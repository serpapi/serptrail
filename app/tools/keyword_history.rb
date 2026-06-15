class KeywordHistory < RubyLLM::Tool
  desc "Get ranking history for one or more tracked keyword/site combinations from the database"

  params do
    string :domain, description: "Single site domain, e.g. apple.com", required: false
    array :domains, of: :string, description: "Multiple site domains", required: false
    string :query, description: "Single keyword query", required: false
    array :queries, of: :string, description: "Multiple keyword queries", required: false
    string :location, description: "Single search location/country code, e.g. us", required: false
    array :locations, of: :string, description: "Multiple search location/country codes", required: false
    integer :limit, description: "Number of recent checks per keyword/site to return (default 10)", minimum: 1, maximum: 100, required: false
  end

  def execute(domain: nil, domains: nil, query: nil, queries: nil, location: nil, locations: nil, limit: 10)
    domain_values = normalized_values(domain, domains)
    query_values = normalized_values(query, queries)
    location_values = normalized_values(location, locations)

    return { error: "Provide at least one domain and one keyword query" } if domain_values.empty? || query_values.empty?

    targets = KeywordTarget.includes(:keyword, :site)
      .joins(:keyword, :site)
      .where(keywords: { query: query_values }, sites: { domain: domain_values })
      .order("sites.domain", "keywords.query")

    found_pairs = targets.map { |target| [ target.site.domain, target.keyword.query ] }

    {
      results: targets.map { |target| history_for(target, location_values: location_values, limit: limit) },
      missing: missing_pairs(domain_values, query_values, found_pairs)
    }
  end

  private

  def history_for(target, location_values:, limit:)
    checks = target.checks.success.order(checked_at: :desc)
    checks = checks.where(location: location_values) if location_values.any?
    checks = checks.limit(limit.to_i.clamp(1, 100))

    {
      keyword: target.keyword.query,
      domain: target.site.domain,
      locations: location_values.presence || target.keyword.locations,
      current_position: checks.first&.position,
      change: position_change_for(target, location_values),
      history: checks.map do |check|
        {
          date: check.checked_at.to_date,
          location: check.location,
          position: check.position,
          url: check.url
        }
      end
    }
  end

  def position_change_for(target, location_values)
    return target.position_change if location_values.empty?
    return target.position_change(location: location_values.first) if location_values.one?

    nil
  end

  def missing_pairs(domain_values, query_values, found_pairs)
    domain_values.product(query_values).filter_map do |domain, query|
      { domain: domain, keyword: query } unless found_pairs.include?([ domain, query ])
    end
  end

  def normalized_values(*values)
    values.flatten.compact.map(&:to_s).map(&:strip).reject(&:blank?).uniq
  end
end
