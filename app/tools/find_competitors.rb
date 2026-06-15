class FindCompetitors < RubyLLM::Tool
  desc "Find domains that rank in the top results for a query, excluding a given domain"

  params do
    string :query, description: "The search query"
    string :exclude_domain, description: "Your domain to exclude from results"
    integer :top_n, description: "How many top results to scan (default 20)", minimum: 1, maximum: 100, required: false
  end

  def execute(query:, exclude_domain:, top_n: 20)
    client = SerpApi::Client.new(engine: "google", api_key: Tenant.instance.serpapi_key)
    results = client.search(q: query, num: top_n.to_i.clamp(1, 100))

    (results[:organic_results] || []).filter_map do |result|
      link = result[:link].to_s
      next if link.blank? || link.include?(exclude_domain)

      domain = URI.parse(link).host
      next if domain.blank?

      { position: result[:position], domain: domain, title: result[:title] }
    rescue URI::InvalidURIError
      nil
    end
  ensure
    client&.close
  end
end
