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
    organic   = results[:organic_results] || []
    match     = organic.each_with_index.find { |result, _| result[:link]&.include?(domain) }

    ao        = results[:ai_overview]
    ao_source = ao&.dig(:sources)&.find { |s| s[:link]&.include?(domain) }

    position, url = if match
      result, _ = match
      [ result[:position], result[:link] ]
    else
      [ nil, nil ]
    end

    {
      position: position,
      url: url,
      serpapi_search_id: search_id,
      ai_overview_present: ao.present?,
      ai_overview_cited: ao_source.present?,
      ai_overview_citation_position: ao_source ? ao[:sources].index(ao_source) + 1 : nil,
      raw_response: results.to_json
    }
  end
end
