class SearchGoogle < RubyLLM::Tool
  description "Search Google and return top organic results for a query"

  params do
    string :query, description: "The search query"
    integer :num, description: "Number of results to return (max 100, default 10)"
  end

  def execute(query:, num: 10)
    client = SerpApi::Client.new(engine: "google", api_key: ENV.fetch("SERPAPI_API_KEY"))
    results = client.search(q: query, num: [num, 100].min)
    client.close

    (results[:organic_results] || []).map do |r|
      { position: r[:position], title: r[:title], url: r[:link], snippet: r[:snippet] }
    end
  end
end
