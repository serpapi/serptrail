require "test_helper"

class KeywordTest < ActiveSupport::TestCase
  test "valid keyword" do
    keyword = Keyword.new(site: sites(:apple), query: "new query")
    assert keyword.valid?
  end

  test "requires query" do
    keyword = Keyword.new(site: sites(:apple), query: "")
    assert_not keyword.valid?
  end

  test "query must be unique per site" do
    keyword = Keyword.new(site: sites(:apple), query: "iphone 18")
    assert_not keyword.valid?
    assert_includes keyword.errors[:query], "has already been taken"
  end

  test "same query allowed on different site" do
    keyword = Keyword.new(site: sites(:gsmarena), query: "iphone 18")
    assert keyword.valid?
  end

  test "check_frequency defaults to daily" do
    keyword = Keyword.new(site: sites(:apple), query: "test")
    assert_equal "daily", keyword.check_frequency
  end

  test "due_for_check includes keywords needing check" do
    due = Keyword.due_for_check
    assert_includes due, keywords(:apple_iphone18)
    assert_includes due, keywords(:never_checked)
  end

  test "due_for_check excludes disabled site keywords" do
    due = Keyword.due_for_check
    assert_not_includes due, keywords(:disabled_keyword)
  end

  test "due_for_check excludes recently checked weekly keywords" do
    due = Keyword.due_for_check
    assert_not_includes due, keywords(:apple_iphone18_pro)
  end

  test "latest_check returns most recent success check" do
    keyword = keywords(:apple_iphone18)
    assert_equal checks(:apple_iphone18_us_latest), keyword.latest_check
  end

  test "previous_check returns second most recent success check" do
    keyword = keywords(:apple_iphone18)
    assert_equal checks(:apple_iphone18_us_previous), keyword.previous_check
  end

  test "position_change calculates improvement" do
    keyword = keywords(:apple_iphone18)
    # was position 4, now position 1 → improved by 3
    assert_equal 3, keyword.position_change
  end
end
