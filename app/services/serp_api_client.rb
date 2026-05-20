class SerpApiClient
  def initialize(api_key: nil)
    @api_key = api_key
  end

  def search(query, location:)
    api_key = @api_key || Tenant.instance.serpapi_key
    client = SerpApi::Client.new(engine: "google", api_key: api_key)
    client.search(q: query, num: 100, gl: location)
  ensure
    client&.close
  end

  def extract_position(results, domain)
    organic = results[:organic_results] || []
    match = organic.each_with_index.find { |result, _| result[:link]&.include?(domain) }

    ao = results[:ai_overview]
    ao_sources = ao&.dig(:sources) || []
    ao_source = ao_sources.find { |source| source[:link]&.include?(domain) }

    position, url = if match
      result, = match
      [ result[:position], result[:link] ]
    else
      [ nil, nil ]
    end

    {
      position: position,
      url: url,
      ai_overview_present: ao.present?,
      ai_overview_cited: ao_source.present?,
      ai_overview_citation_position: ao_source ? ao_sources.index(ao_source) + 1 : nil
    }
  end

  def check_position(query, domain, location:)
    results = search(query, location: location)
    extract_position(results, domain).merge(
      serpapi_search_id: results.dig(:search_metadata, :id),
      raw_response: results.to_json
    )
  end
end
