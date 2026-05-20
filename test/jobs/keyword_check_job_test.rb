require "test_helper"

class KeywordCheckJobTest < ActiveJob::TestCase
  test "creates a check record on success" do
    keyword = keywords(:apple_iphone18)

    results = {
      search_metadata: { id: "search_123" },
      organic_results: [ { position: 3, link: "https://apple.com/page" } ]
    }
    SerpApiClient.any_instance.stubs(:search).returns(results)

    assert_difference([ "SearchRun.count", "Check.count" ]) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "success", check.status
    assert_equal 3, check.position
    assert_equal "us", check.location
    assert_equal keyword.query, check.query
    assert_equal "search_123", check.search_run.serpapi_search_id
    assert_equal keyword_targets(:apple_iphone18), check.keyword_target
    assert_not_nil keyword.reload.last_checked_at
  end

  test "reuses one search run for all keyword targets" do
    keyword = keywords(:apple_iphone18)
    keyword.keyword_targets.create!(site: sites(:bestbuy))
    results = {
      search_metadata: { id: "shared_search" },
      organic_results: [
        { position: 1, link: "https://apple.com/page" },
        { position: 5, link: "https://bestbuy.com/page" }
      ]
    }
    SerpApiClient.any_instance.expects(:search).once.returns(results)

    assert_difference("SearchRun.count", 1) do
      assert_difference("Check.count", 2) do
        KeywordCheckJob.perform_now(keyword, "us")
      end
    end

    search_run = SearchRun.order(:created_at).last
    assert_equal "shared_search", search_run.serpapi_search_id
    assert_equal 2, search_run.checks.count
    assert_equal [ 1, 5 ], search_run.checks.order(:position).pluck(:position)
  end

  test "creates a search run even when keyword has no targets" do
    keyword = Keyword.create!(query: "standalone query", locations: [ "us" ])
    results = {
      search_metadata: { id: "targetless_search" },
      organic_results: [ { position: 1, link: "https://apple.com/page" } ]
    }
    SerpApiClient.any_instance.expects(:search).once.returns(results)

    assert_difference("SearchRun.count", 1) do
      assert_no_difference("Check.count") do
        KeywordCheckJob.perform_now(keyword, "us")
      end
    end

    search_run = keyword.search_runs.order(:created_at).last
    assert_equal "success", search_run.status
    assert_equal "targetless_search", search_run.serpapi_search_id
    assert_not_nil keyword.reload.last_checked_at
  end

  test "creates historical checks when target is added after search runs exist" do
    keyword = Keyword.create!(query: "historical target query", locations: [ "us" ])
    keyword.search_runs.create!(
      query: keyword.query,
      location: "us",
      status: :success,
      checked_at: 1.day.ago,
      raw_response: {
        search_metadata: { id: "historical_search" },
        organic_results: [ { position: 4, link: "https://apple.com/page" } ]
      }.to_json
    )

    target = keyword.keyword_targets.create!(site: sites(:apple))

    assert_difference("Check.count", 1) do
      MissingChecksBackfillJob.perform_now(keyword_target: target)
    end

    check = keyword.checks.order(:created_at).last
    assert_equal "success", check.status
    assert_equal 4, check.position
    assert_equal "https://apple.com/page", check.url
    assert_equal "us", check.location
  end

  test "creates a failed check record on error" do
    keyword = keywords(:apple_iphone18)

    SerpApiClient.any_instance.stubs(:search).raises(StandardError.new("API error"))

    assert_difference([ "SearchRun.count", "Check.count" ]) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "failed", check.status
    assert_equal "API error", check.error_message
    assert_equal "failed", check.search_run.status
    assert_equal "us", check.location
    assert_equal keyword.query, check.query
  end
end
