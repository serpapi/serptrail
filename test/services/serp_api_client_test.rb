require "test_helper"

class SerpApiClientTest < ActiveSupport::TestCase
  setup do
    @client = SerpApiClient.new
  end

  test "search requests an explicit Google result page" do
    api_client = mock("serpapi_client")
    SerpApi::Client.expects(:new).with(engine: "google", api_key: tenants(:default).serpapi_key).returns(api_client)
    api_client.expects(:search).with(q: "iphone 18", num: 10, start: 20, gl: "us").returns(organic_results: [])
    api_client.expects(:close)

    @client.search("iphone 18", location: "us", page: 3)
  end

  test "search sends city location and matching country localization" do
    api_client = mock("serpapi_client")
    SerpApi::Client.expects(:new).with(engine: "google", api_key: tenants(:default).serpapi_key).returns(api_client)
    api_client.expects(:search).with(
      q: "coffee",
      num: 10,
      start: 0,
      location: "Austin,Texas,United States",
      gl: "us"
    ).returns(organic_results: [])
    api_client.expects(:close)

    location = SearchLocation.city_value(canonical_name: "Austin,Texas,United States", country_code: "us")
    @client.search("coffee", location: location)
  end

  test "position check preserves the existing top 100 lookup" do
    results = { organic_results: [] }
    @client.expects(:search).with("iphone 18", location: "us", page: 1, results_per_page: 100).returns(results)

    @client.check_position("iphone 18", "apple.com", location: "us")
  end

  test "link matches identical domains" do
    assert @client.link_matches_domain?("https://example.com/page", "example.com")
    assert @client.link_matches_domain?("example.com", "https://example.com/about")
  end

  test "link matches domains with www. disregarded" do
    assert @client.link_matches_domain?("https://www.example.com/page", "example.com")
    assert @client.link_matches_domain?("https://example.com/page", "www.example.com")
  end

  test "link normalizes hostnames before matching" do
    assert @client.link_matches_domain?("https://EXAMPLE.com/page", "example.com")
    assert @client.link_matches_domain?("https://EXAMPLE.com/page", "example.com")
  end

  test "link does not match subdomains by default" do
    assert_not @client.link_matches_domain?("https://shop.example.com/page", "example.com")
  end

  test "link matches subdomains when enabled" do
    assert @client.link_matches_domain?("https://shop.example.com/page", "example.com", match_subdomains: true)
    assert @client.link_matches_domain?("https://nested.shop.example.com/page", "example.com", match_subdomains: true)
  end

  test "link matches subdomains when enabled and with www. disregarded" do
    assert @client.link_matches_domain?("https://www.shop.example.com/page", "www.example.com", match_subdomains: true)
    assert @client.link_matches_domain?("https://www.nested.shop.example.com/page", "www.example.com", match_subdomains: true)
  end

  test "link does not match unrelated domains" do
    assert_not @client.link_matches_domain?("https://notexample.com/page", "example.com", match_subdomains: true)
    assert_not @client.link_matches_domain?("https://example.org/example.com", "example.com", match_subdomains: true)
  end

  test "link does not match blank or invalid values" do
    assert_not @client.link_matches_domain?(nil, "example.com")
    assert_not @client.link_matches_domain?("https://example.com/page", "")
    assert_not @client.link_matches_domain?("http://%", "example.com")
    assert_not @client.link_matches_domain?("http://example.com", "     ")
  end
end
