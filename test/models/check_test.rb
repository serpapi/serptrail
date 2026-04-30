require "test_helper"

class CheckTest < ActiveSupport::TestCase
  test "valid check" do
    check = Check.new(keyword: keywords(:ruby), status: :success, checked_at: Time.current, location: "us")
    assert check.valid?
  end

  test "requires status" do
    check = Check.new(keyword: keywords(:ruby), status: nil, checked_at: Time.current, location: "us")
    assert_not check.valid?
  end

  test "requires checked_at" do
    check = Check.new(keyword: keywords(:ruby), status: :success, checked_at: nil, location: "us")
    assert_not check.valid?
  end

  test "requires location" do
    check = Check.new(keyword: keywords(:ruby), status: :success, checked_at: Time.current, location: nil)
    assert_not check.valid?
  end

  test "position can be nil for not ranked" do
    check = Check.new(keyword: keywords(:ruby), status: :success, checked_at: Time.current, location: "us", position: nil)
    assert check.valid?
  end
end
