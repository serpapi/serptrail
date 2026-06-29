require "test_helper"

class CheckKeywordPositionTest < ActiveSupport::TestCase
  test "declares location as optional in RubyLLM schema" do
    schema = CheckKeywordPosition.new.params_schema

    assert_equal [ "query", "domain" ], schema["required"]
    assert_equal "string", schema.dig("properties", "location", "type")
  end

  test "delegates to SerpApiClient with default location" do
    client = mock("serp_api_client")
    SerpApiClient.expects(:new).returns(client)
    client.expects(:check_position).with("iphone 18", "apple.com", location: "us", match_subdomains: false).returns(position: 1)

    assert_equal({ position: 1 }, CheckKeywordPosition.new.execute(query: "iphone 18", domain: "apple.com", location: "", match_subdomains: false))
  end
end
