require "test_helper"

class KeywordHistoryTest < ActiveSupport::TestCase
  test "declares single and multi-target inputs in RubyLLM schema" do
    schema = KeywordHistory.new.params_schema

    assert_empty schema["required"]
    assert_equal "string", schema.dig("properties", "domain", "type")
    assert_equal "array", schema.dig("properties", "domains", "type")
    assert_equal "string", schema.dig("properties", "domains", "items", "type")
    assert_equal "array", schema.dig("properties", "queries", "type")
    assert_equal "integer", schema.dig("properties", "limit", "type")
    assert_equal 1, schema.dig("properties", "limit", "minimum")
    assert_equal 100, schema.dig("properties", "limit", "maximum")
  end

  test "returns tracked keyword history for a single site and keyword" do
    result = KeywordHistory.new.execute(domain: "apple.com", query: "iphone 18", location: "us", limit: "2")
    history = result[:results].first

    assert_empty result[:missing]
    assert_equal "iphone 18", history[:keyword]
    assert_equal "apple.com", history[:domain]
    assert_equal [ "us" ], history[:locations]
    assert_equal 1, history[:current_position]
    assert_equal 3, history[:change]
    assert_equal 2, history[:history].size
    assert_equal({ date: checks(:apple_iphone18_us_latest).checked_at.to_date, location: "us", position: 1, url: "https://apple.com/iphone-18" }, history[:history].first)
  end

  test "returns histories for multiple websites and keywords" do
    result = KeywordHistory.new.execute(
      domains: [ "apple.com", "bestbuy.com" ],
      queries: [ "iphone 18", "iphone 18 pro" ],
      location: "us",
      limit: 1
    )

    assert_empty result[:missing]
    assert_equal 4, result[:results].size
    assert_equal [
      [ "apple.com", "iphone 18" ],
      [ "apple.com", "iphone 18 pro" ],
      [ "bestbuy.com", "iphone 18" ],
      [ "bestbuy.com", "iphone 18 pro" ]
    ], result[:results].map { |history| [ history[:domain], history[:keyword] ] }
    assert_equal [ 1 ], result[:results].find { |history| history[:domain] == "apple.com" && history[:keyword] == "iphone 18" }[:history].map { |check| check[:position] }
    assert_equal [ 5 ], result[:results].find { |history| history[:domain] == "bestbuy.com" && history[:keyword] == "iphone 18" }[:history].map { |check| check[:position] }
  end

  test "reports missing keyword and site combinations" do
    result = KeywordHistory.new.execute(domains: [ "apple.com", "example.com" ], queries: [ "iphone 18", "missing" ])

    assert_equal 1, result[:results].size
    assert_equal [
      { domain: "apple.com", keyword: "missing" },
      { domain: "example.com", keyword: "iphone 18" },
      { domain: "example.com", keyword: "missing" }
    ], result[:missing]
  end

  test "returns error when domain or query input is missing" do
    result = KeywordHistory.new.execute(domain: "apple.com")

    assert_equal({ error: "Provide at least one domain and one keyword query" }, result)
  end
end
