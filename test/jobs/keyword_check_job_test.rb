require "test_helper"

class KeywordCheckJobTest < ActiveJob::TestCase
  test "creates a check record on success" do
    keyword = keywords(:apple_iphone18)

    results = {
      search_metadata: { id: "search_123" },
      organic_results: [ { position: 3, link: "https://apple.com/page" } ]
    }
    SerpApiClient.any_instance.stubs(:search).returns(results)

    assert_difference([ "SearchRun.count", "SearchRunPage.count", "Check.count" ]) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "success", check.status
    assert_equal 3, check.position
    assert_equal "us", check.location
    assert_equal keyword.query, check.query
    assert_equal "search_123", check.search_run.serpapi_search_id
    assert_equal [ 1 ], check.search_run.search_run_pages.pluck(:page_number)
    assert_equal keyword_targets(:apple_iphone18), check.keyword_target
    assert_not_nil keyword.reload.last_checked_at
  end

  test "stores precise city parameters on search run pages" do
    location = SearchLocation.city_value(canonical_name: "Austin,Texas,United States", country_code: "us")
    keyword = Keyword.create!(query: "coffee in austin", locations: [ location ])
    results = {
      search_metadata: { id: "city_search" },
      organic_results: []
    }
    SerpApiClient.any_instance.expects(:search).with(keyword.query, location: location, page: 1).returns(results)

    KeywordCheckJob.perform_now(keyword, location)

    search_params = keyword.search_runs.order(:created_at).last.search_run_pages.first.search_params.symbolize_keys
    assert_equal "Austin,Texas,United States", search_params[:location]
    assert_equal "us", search_params[:gl]
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
    assert_equal 1, search_run.search_run_pages.count
  end

  test "fetches and combines all configured result pages" do
    keyword = keywords(:apple_iphone18)
    keyword.update!(search_pages: 3)
    client = SerpApiClient.any_instance
    client.expects(:search).with(keyword.query, location: "us", page: 1).returns(
      search_metadata: { id: "page_1" },
      organic_results: [ { position: 1, link: "https://example.com/one" } ],
      ai_overview: { sources: [ { link: "https://apple.com/citation" } ] }
    )
    client.expects(:search).with(keyword.query, location: "us", page: 2).returns(
      search_metadata: { id: "page_2" },
      organic_results: [ { position: 1, link: "https://example.com/two" } ]
    )
    client.expects(:search).with(keyword.query, location: "us", page: 3).returns(
      search_metadata: { id: "page_3" },
      organic_results: [ { position: 1, link: "https://apple.com/result" } ]
    )

    assert_difference("SearchRunPage.count", 3) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    search_run = keyword.search_runs.order(:created_at).last
    check = search_run.checks.find_by!(keyword_target: keyword_targets(:apple_iphone18))
    assert_equal 3, search_run.requested_pages
    assert_equal [ 0, 10, 20 ], search_run.search_run_pages.pluck(:start)
    assert_equal [ "page_1", "page_2", "page_3" ], search_run.search_run_pages.pluck(:serpapi_search_id)
    assert_equal 21, check.position
    assert check.ai_overview_cited?
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



  test "creates failed page records when SerpApi is not configured" do
    keyword = keywords(:apple_iphone18)
    keyword.update!(search_pages: 2)
    tenants(:default).update!(serpapi_key: "")

    assert_difference("SearchRunPage.count", 2) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    search_run = keyword.search_runs.order(:created_at).last
    assert search_run.failed?
    assert_equal [ "failed", "failed" ], search_run.search_run_pages.pluck(:status)
    assert_equal [ 0, 10 ], search_run.search_run_pages.pluck(:start)
  end

  test "creates a failed check record on error" do
    keyword = keywords(:apple_iphone18)

    SerpApiClient.any_instance.stubs(:search).raises(StandardError.new("API error"))

    assert_difference([ "SearchRun.count", "SearchRunPage.count", "Check.count" ]) do
      KeywordCheckJob.perform_now(keyword, "us")
    end

    check = keyword.checks.order(checked_at: :desc).first
    assert_equal "failed", check.status
    assert_equal "API error", check.error_message
    assert_equal "failed", check.search_run.status
    assert_equal "failed", check.search_run.search_run_pages.first.status
    assert_equal "us", check.location
    assert_equal keyword.query, check.query
  end
end
