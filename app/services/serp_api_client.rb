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

  def extract_position(results, domain, match_subdomains: false)
    organic = results[:organic_results] || []
    match = organic.each_with_index.find { |result, _| link_matches_domain?(result[:link], domain, match_subdomains: match_subdomains) }

    ao = results[:ai_overview]
    ao_sources = ao&.dig(:sources) || []
    ao_source = ao_sources.find { |source| link_matches_domain?(source[:link], domain, match_subdomains: match_subdomains) }

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

  def check_position(query, domain, location:, match_subdomains: false)
    results = search(query, location: location)
    extract_position(results, domain, match_subdomains: match_subdomains).merge(
      serpapi_search_id: results.dig(:search_metadata, :id),
      raw_response: results.to_json
    )
  end

  def link_matches_domain?(link, domain, match_subdomains: false)
    link_host = extract_hostname(link)
    domain = extract_hostname(domain)

    return false if link_host.blank? || domain.blank?

    link_host == domain || (match_subdomains && link_host.end_with?(".#{domain}"))
  end

  def extract_hostname(value)
    hostname = (value.to_s.include?("/") ? URI.parse(value)&.hostname : value).to_s

    hostname.strip.downcase.delete_prefix("www.").delete_suffix(".")
  rescue URI::InvalidURIError
    nil
  end
end
