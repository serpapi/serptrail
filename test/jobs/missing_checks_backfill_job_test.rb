require "test_helper"

class MissingChecksBackfillJobTest < ActiveJob::TestCase
  test "creates missing checks for all targets from successful search runs" do
    keyword = Keyword.create!(query: "missing checks keyword", locations: [ "us" ])
    apple_target = keyword.keyword_targets.create!(site: sites(:apple))
    bestbuy_target = keyword.keyword_targets.create!(site: sites(:bestbuy))
    search_run = keyword.search_runs.create!(
      query: keyword.query,
      location: "us",
      status: :success,
      checked_at: 2.days.ago,
      raw_response: {
        search_metadata: { id: "search_run_for_missing_checks" },
        organic_results: [
          { position: 2, link: "https://apple.com/page" },
          { position: 7, link: "https://bestbuy.com/page" }
        ]
      }.to_json
    )

    assert_difference("Check.count", 2) do
      MissingChecksBackfillJob.perform_now(keyword: keyword)
    end

    assert_equal 2, apple_target.checks.find_by(search_run: search_run).position
    assert_equal 7, bestbuy_target.checks.find_by(search_run: search_run).position
  end

  test "does not duplicate existing checks" do
    keyword = Keyword.create!(query: "no duplicate checks keyword", locations: [ "us" ])
    target = keyword.keyword_targets.create!(site: sites(:apple))
    search_run = keyword.search_runs.create!(
      query: keyword.query,
      location: "us",
      status: :success,
      checked_at: 2.days.ago,
      raw_response: {
        organic_results: [ { position: 2, link: "https://apple.com/page" } ]
      }.to_json
    )
    target.checks.create!(
      keyword: keyword,
      search_run: search_run,
      query: search_run.query,
      location: search_run.location,
      checked_at: search_run.checked_at,
      position: 2,
      status: :success
    )

    assert_no_difference("Check.count") do
      MissingChecksBackfillJob.perform_now(keyword: keyword)
    end
  end



  test "creates failed checks for failed search runs" do
    keyword = Keyword.create!(query: "failed search run keyword", locations: [ "us" ])
    target = keyword.keyword_targets.create!(site: sites(:apple))
    search_run = keyword.search_runs.create!(
      query: keyword.query,
      location: "us",
      status: :failed,
      error_message: "API error",
      checked_at: 2.days.ago
    )

    assert_difference("Check.count", 1) do
      MissingChecksBackfillJob.perform_now(keyword: keyword)
    end

    check = target.checks.find_by!(search_run: search_run)
    assert_equal "failed", check.status
    assert_equal "API error", check.error_message
  end
end
