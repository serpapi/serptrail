require "test_helper"

class SearchRunsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = auth_headers
    @keyword = keywords(:apple_iphone18)
    @search_run = search_runs(:apple_iphone18_us_latest)
  end

  test "show search run with organic results" do
    get keyword_search_run_url(@keyword, @search_run), headers: @headers
    assert_response :success
    assert_select "turbo-frame#search-run-results"
    assert_select ".organic-result"
  end

  test "show search run with no raw response" do
    @search_run.update!(raw_response: nil)
    get keyword_search_run_url(@keyword, @search_run), headers: @headers
    assert_response :success
    assert_select "turbo-frame#search-run-results"
    assert_select ".muted", text: "No search results recorded for this run."
  end
end
