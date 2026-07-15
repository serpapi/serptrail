require "test_helper"

class LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = auth_headers
  end

  test "returns no locations for a short query" do
    get locations_url, params: { q: "a" }, headers: @headers

    assert_response :success
    assert_equal [], response.parsed_body
  end

  test "returns SerpApi city options" do
    locations = [
      {
        value: "city:us:Austin,Texas,United States",
        name: "Austin, Texas, United States",
        country_code: "us",
        target_type: "City"
      }
    ]
    SerpApiLocationsClient.any_instance.expects(:search).with("Austin").returns(locations)

    get locations_url, params: { q: "Austin" }, headers: @headers

    assert_response :success
    assert_equal locations.as_json, response.parsed_body
  end
end
