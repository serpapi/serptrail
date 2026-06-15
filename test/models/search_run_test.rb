require "test_helper"

class SearchRunTest < ActiveSupport::TestCase
  test "engine defaults to google" do
    search_run = SearchRun.new(
      keyword: keywords(:apple_iphone18),
      query: "iphone 18",
      location: "us",
      status: :pending,
      checked_at: Time.current
    )

    assert_equal "google", search_run.engine
    assert search_run.google?
  end
end
