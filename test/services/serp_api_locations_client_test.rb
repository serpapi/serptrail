require "test_helper"

class SerpApiLocationsClientTest < ActiveSupport::TestCase
  test "returns normalized city options" do
    response = stub(
      code: "200",
      body: [
        {
          id: "city-id",
          canonical_name: "Prague,Prague,Czechia",
          country_code: "CZ",
          target_type: "City"
        },
        {
          id: "region-id",
          canonical_name: "Prague,Czechia",
          country_code: "CZ",
          target_type: "Region"
        }
      ].to_json
    )
    Net::HTTP.expects(:get_response).with do |uri|
      uri.host == "serpapi.com" && Rack::Utils.parse_query(uri.query) == { "q" => "Prague", "limit" => "10" }
    end.returns(response)

    locations = SerpApiLocationsClient.new.search("Prague")

    assert_equal 1, locations.size
    assert_equal "city:cz:Prague,Prague,Czechia", locations.first[:value]
    assert_equal "Prague, Prague, Czechia", locations.first[:name]
    assert_equal "cz", locations.first[:country_code]
  end
end
