require "test_helper"

class SearchLocationTest < ActiveSupport::TestCase
  test "keeps country locations as country localization" do
    location = SearchLocation.new("us")

    assert_not location.city?
    assert_equal "us", location.country_code
    assert_nil location.canonical_name
    assert_equal({ gl: "us" }, location.search_params)
  end

  test "provides city and country parameters for city locations" do
    value = SearchLocation.city_value(canonical_name: "Austin,Texas,United States", country_code: "US")
    location = SearchLocation.new(value)

    assert location.city?
    assert_equal "us", location.country_code
    assert_equal "Austin,Texas,United States", location.canonical_name
    assert_equal "Austin, Texas, United States", location.display_name
    assert_equal({ location: "Austin,Texas,United States", gl: "us" }, location.search_params)
  end
end
