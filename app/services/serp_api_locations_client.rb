require "net/http"

class SerpApiLocationsClient
  ENDPOINT = "https://serpapi.com/locations.json"

  class Error < StandardError; end

  def search(query)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(q: query, limit: 10)
    response = Net::HTTP.get_response(uri)
    raise Error, "SerpApi locations request failed with status #{response.code}" unless response.code.to_i.between?(200, 299)

    JSON.parse(response.body).filter_map do |location|
      next unless location["target_type"] == "City"

      canonical_name = location.fetch("canonical_name")
      country_code = location.fetch("country_code").downcase
      {
        value: SearchLocation.city_value(canonical_name: canonical_name, country_code: country_code),
        name: canonical_name.gsub(",", ", "),
        country_code: country_code,
        target_type: location.fetch("target_type")
      }
    end
  rescue Error
    raise
  rescue JSON::ParserError, KeyError => e
    raise Error, "SerpApi locations returned an invalid response: #{e.message}"
  rescue StandardError => e
    raise Error, "SerpApi locations request failed: #{e.message}"
  end
end
