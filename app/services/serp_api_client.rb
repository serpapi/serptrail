class SerpApiClient
  def initialize(api_key: ENV.fetch("SERPAPI_API_KEY"))
    @api_key = api_key
  end

  def check_position(query, domain, location: "us")
    client = SerpApi::Client.new(engine: "google", api_key: @api_key)
    results = client.search(q: query, num: 100, gl: location)
    client.close

    organic = results[:organic_results] || []
    match = organic.each_with_index.find { |result, _| result[:link]&.include?(domain) }

    if match
      result, _ = match
      { position: result[:position], url: result[:link] }
    else
      { position: nil, url: nil }
    end
  end
end
