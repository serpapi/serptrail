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
    assert_equal 1, search_run.requested_pages
  end

  test "combines organic results from successful pages and AI overview from page one" do
    search_run = SearchRun.create!(
      keyword: keywords(:apple_iphone18),
      query: "iphone 18",
      location: "us",
      requested_pages: 2,
      status: :success,
      checked_at: Time.current
    )
    search_run.search_run_pages.create!(
      page_number: 1,
      start: 0,
      status: :success,
      raw_response: {
        organic_results: [ { position: 1, link: "https://example.com/one" } ],
        ai_overview: { text: "Overview" }
      }.to_json
    )
    search_run.search_run_pages.create!(
      page_number: 2,
      start: 10,
      status: :success,
      raw_response: {
        organic_results: [ { position: 1, link: "https://example.com/two" } ],
        ai_overview: { text: "Ignored" }
      }.to_json
    )

    results = search_run.combined_results

    assert_equal [ 1, 11 ], results[:organic_results].pluck(:position)
    assert_equal({ text: "Overview" }, results[:ai_overview])
  end
end
