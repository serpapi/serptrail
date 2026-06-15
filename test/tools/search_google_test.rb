require "test_helper"

class SearchGoogleTest < ActiveSupport::TestCase
  test "declares optional result count in RubyLLM schema" do
    schema = SearchGoogle.new.params_schema

    assert_equal [ "query" ], schema["required"]
    assert_equal "integer", schema.dig("properties", "num", "type")
    assert_equal 1, schema.dig("properties", "num", "minimum")
    assert_equal 100, schema.dig("properties", "num", "maximum")
  end

  test "returns organic results from SerpApi" do
    client = mock("serpapi_client")
    SerpApi::Client.expects(:new).with(engine: "google", api_key: tenants(:default).serpapi_key).returns(client)
    client.expects(:search).with(q: "iphone 18", num: 100).returns(
      organic_results: [
        { position: 1, title: "Apple", link: "https://apple.com/iphone-18", snippet: "Official page" }
      ]
    )
    client.expects(:close)

    results = SearchGoogle.new.execute(query: "iphone 18", num: "500")

    assert_equal [
      { position: 1, title: "Apple", url: "https://apple.com/iphone-18", snippet: "Official page" }
    ], results
  end
end
