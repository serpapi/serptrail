class SearchGoogle < RubyLLM::Tool
  desc "Search Google and return top organic results for a query"

  params do
    string :query, description: "The search query"
    integer :num, description: "Number of results to return (max 100, default 10)", minimum: 1, maximum: 100, required: false
  end

  def execute(query:, num: 10)
    client = SerpApi::Client.new(engine: "google", api_key: Tenant.instance.serpapi_key)
    results = client.search(q: query, num: num.to_i.clamp(1, 100))

    (results[:organic_results] || []).map do |r|
      { position: r[:position], title: r[:title], url: r[:link], snippet: r[:snippet] }
    end
  ensure
    client&.close
  end
end
