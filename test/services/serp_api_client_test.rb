require "test_helper"

class SerpApiClientTest < ActiveSupport::TestCase
  setup do
    @client = SerpApiClient.new
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
    assert @client.link_matches_domain?("https://www.shop.example.com/page", "example.com", match_subdomains: true)
    assert @client.link_matches_domain?("https://www.nested.shop.example.com/page", "example.com", match_subdomains: true)
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
