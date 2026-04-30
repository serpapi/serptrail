require "test_helper"

class KeywordCheckJobTest < ActiveJob::TestCase
  test "creates a check record on success" do
    keyword = keywords(:ruby)

    SerpApiClient.any_instance.stubs(:check_position).returns({ position: 3, url: "https://example.com/page" })

    assert_difference("Check.count") do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "success", check.status
    assert_equal 3, check.position
    assert_equal "us", check.location
    assert_not_nil keyword.reload.last_checked_at
  end

  test "creates a failed check record on error" do
    keyword = keywords(:ruby)

    SerpApiClient.any_instance.stubs(:check_position).raises(StandardError.new("API error"))

    assert_difference("Check.count") do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "failed", check.status
    assert_equal "API error", check.error_message
    assert_equal "us", check.location
  end
end
