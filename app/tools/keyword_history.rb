class KeywordHistory < RubyLLM::Tool
  description "Get ranking history for a tracked keyword on a site from the database"

  params do
    string :domain, description: "The site domain"
    string :query, description: "The keyword query"
    integer :limit, description: "Number of recent checks to return (default 10)"
  end

  def execute(domain:, query:, limit: 10)
    keyword = Keyword.joins(:site).find_by(query: query, sites: { domain: domain })
    return { error: "Keyword not tracked" } unless keyword

    checks = keyword.checks.where(status: "success").order(checked_at: :desc).limit(limit)
    {
      keyword: query,
      domain: domain,
      current_position: checks.first&.position,
      change: keyword.position_change,
      history: checks.map { |c| { date: c.checked_at.to_date, position: c.position, url: c.url } }
    }
  end
end
