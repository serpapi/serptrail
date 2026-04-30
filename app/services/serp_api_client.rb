class SerpApiClient
  def initialize(api_key: nil)
    @api_key = api_key
  end

  def check_position(query, domain, location:)
    api_key = @api_key || Tenant.instance.serpapi_key
    client = SerpApi::Client.new(engine: "google", api_key: api_key)
    results = client.search(q: query, num: 100, gl: location)
    client.close

    search_id = results.dig(:search_metadata, :id)
    organic = results[:organic_results] || []
    match = organic.each_with_index.find { |result, _| result[:link]&.include?(domain) }

    if match
      result, _ = match
      { position: result[:position], url: result[:link], serpapi_search_id: search_id }
    else
      { position: nil, url: nil, serpapi_search_id: search_id }
    end
  end
end
