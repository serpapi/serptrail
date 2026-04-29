class FindCompetitors < RubyLLM::Tool
  description "Find domains that rank in the top results for a query, excluding a given domain"

  params do
    string :query, description: "The search query"
    string :exclude_domain, description: "Your domain to exclude from results"
    integer :top_n, description: "How many top results to scan (default 20)"
  end

  def execute(query:, exclude_domain:, top_n: 20)
    client = SerpApi::Client.new(engine: "google", api_key: Tenant.instance.serpapi_key)
    results = client.search(q: query, num: top_n)
    client.close

    (results[:organic_results] || [])
      .reject { |r| r[:link]&.include?(exclude_domain) }
      .map { |r| { position: r[:position], domain: URI.parse(r[:link]).host, title: r[:title] } }
  end
end
