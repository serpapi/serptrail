require "test_helper"

class SerpApiCreditEstimatorTest < ActiveSupport::TestCase
  test "estimates monthly credits from frequency, locations, and search depth" do
    keywords = [
      Keyword.new(check_frequency: "daily", locations: %w[us gb], search_pages: 2),
      Keyword.new(check_frequency: "weekly", locations: [ "us" ], search_pages: 3),
      Keyword.new(check_frequency: "biweekly", locations: %w[us gb], search_pages: 1),
      Keyword.new(check_frequency: "monthly", locations: [ "us" ], search_pages: 5)
    ]

    estimate = SerpApiCreditEstimator.new(keywords: keywords)

    assert_equal 143, estimate.monthly_credits
    assert_equal 4, estimate.keyword_count
  end

  test "excludes keywords with checking disabled" do
    estimate = SerpApiCreditEstimator.new

    assert_equal Keyword.checking_enabled.count, estimate.keyword_count
    assert_not_includes Keyword.checking_enabled, keywords(:disabled_keyword)
  end
end
