require "test_helper"

class FindCompetitorsTest < ActiveSupport::TestCase
  test "declares optional top_n in RubyLLM schema" do
    schema = FindCompetitors.new.params_schema

    assert_equal [ "query", "exclude_domain" ], schema["required"]
    assert_equal "integer", schema.dig("properties", "top_n", "type")
    assert_equal 100, schema.dig("properties", "top_n", "maximum")
  end

  test "returns competitor domains and skips excluded or invalid results" do
    client = mock("serpapi_client")
    SerpApi::Client.expects(:new).with(engine: "google", api_key: tenants(:default).serpapi_key).returns(client)
    client.expects(:search).with(q: "iphone 18", num: 100).returns(
      organic_results: [
        { position: 1, title: "Apple", link: "https://apple.com/iphone-18" },
        { position: 2, title: "Best Buy", link: "https://www.bestbuy.com/site/iphone-18" },
        { position: 3, title: "Broken", link: "http://[broken" },
        { position: 4, title: "Missing", link: nil }
      ]
    )
    client.expects(:close)

    results = FindCompetitors.new.execute(query: "iphone 18", exclude_domain: "apple.com", top_n: "500")

    assert_equal [
      { position: 2, domain: "www.bestbuy.com", title: "Best Buy" }
    ], results
  end
end
