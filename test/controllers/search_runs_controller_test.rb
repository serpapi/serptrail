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

  test "show separates results when the next page starts" do
    keyword = keywords(:bestbuy_iphone18)
    search_run = search_runs(:bestbuy_iphone18_gb_week_0)

    get keyword_search_run_url(keyword, search_run), headers: @headers

    assert_response :success
    assert_select ".organic-result", count: 20
    assert_select ".organic-results-page-divider", count: 1, text: "Page 2"
  end

  test "show search run with no raw response" do
    @search_run.update!(raw_response: nil)
    @search_run.search_run_pages.update_all(raw_response: nil)
    get keyword_search_run_url(@keyword, @search_run), headers: @headers
    assert_response :success
    assert_select "turbo-frame#search-run-results"
    assert_select ".muted", text: "No search results recorded for this run."
  end
end
