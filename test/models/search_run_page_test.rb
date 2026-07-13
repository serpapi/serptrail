require "test_helper"

class SearchRunPageTest < ActiveSupport::TestCase
  test "fixture pages always contain ten organic results" do
    assert SearchRunPage.all.all? { |page| page.organic_results.size == 10 }
  end

  test "two-page keyword fixtures have matching run and page settings" do
    %i[bestbuy_iphone18 bestbuy_iphone18_pro].each do |fixture_name|
      keyword = keywords(fixture_name)

      assert_equal 2, keyword.search_pages
      assert keyword.search_runs.all? { |run| run.requested_pages == 2 }
      assert keyword.search_runs.all? { |run| run.search_run_pages.size == 2 }

      keyword.checks.where(status: :success).where.not(position: nil).find_each do |check|
        result = check.search_run.combined_results[:organic_results].find { |item| item[:position] == check.position }
        assert_equal check.url, result[:link]
      end
    end
  end

  test "one-page keyword fixtures have one result page" do
    keyword = keywords(:apple_iphone18)

    assert_equal 1, keyword.search_pages
    assert keyword.search_runs.all? { |run| run.requested_pages == 1 }
    assert keyword.search_runs.all? { |run| run.search_run_pages.size == 1 }
  end

  test "normalizes page-relative positions to absolute positions" do
    search_run = keywords(:apple_iphone18).search_runs.create!(
      query: "iphone 18",
      location: "us",
      requested_pages: 3,
      status: :success,
      checked_at: Time.current
    )
    page = search_run.search_run_pages.create!(
      page_number: 3,
      start: 20,
      status: :success,
      raw_response: { organic_results: [ { position: 1, link: "https://apple.com/page" } ] }.to_json
    )

    assert_equal 21, page.organic_results.first[:position]
    assert_equal 3, page.organic_results.first[:page]
  end

  test "preserves absolute positions returned by SerpApi" do
    search_run = keywords(:apple_iphone18).search_runs.create!(
      query: "iphone 18",
      location: "us",
      requested_pages: 3,
      status: :success,
      checked_at: Time.current
    )
    page = search_run.search_run_pages.create!(
      page_number: 3,
      start: 20,
      status: :success,
      raw_response: { organic_results: [ { position: 21, link: "https://apple.com/page" } ] }.to_json
    )

    assert_equal 21, page.organic_results.first[:position]
  end
end
