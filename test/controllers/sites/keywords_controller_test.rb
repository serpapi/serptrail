require "test_helper"

class Sites::KeywordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:apple)
    @keyword = keywords(:apple_iphone18)
    @headers = auth_headers
  end

  test "get new" do
    get new_site_keyword_url(@site), headers: @headers
    assert_response :success
    assert_select "input[type='range'][name='keyword[search_pages]'][min='1'][max='5']"
  end

  test "get import shows search depth slider" do
    get import_site_keywords_url(@site), headers: @headers

    assert_response :success
    assert_select "input[type='range'][name='keyword[search_pages]'][min='1'][max='5']"
  end

  test "create keyword" do
    assert_difference("Keyword.count") do
      assert_enqueued_with(job: KeywordCheckJob) do
        post site_keywords_url(@site), params: { keyword: { query: "new query", check_frequency: "daily", search_pages: 4, locations: [ "us" ] } }, headers: @headers
      end
    end
    assert_redirected_to site_url(@site)
    assert_equal 4, Keyword.find_by!(query: "new query").search_pages
  end

  test "create keyword with invalid data" do
    assert_no_difference("Keyword.count") do
      post site_keywords_url(@site), params: { keyword: { query: "", check_frequency: "daily" } }, headers: @headers
    end
    assert_response :unprocessable_entity
  end

  test "get edit" do
    get edit_site_keyword_url(@site, @keyword), headers: @headers
    assert_response :success
  end

  test "update keyword" do
    patch site_keyword_url(@site, @keyword), params: { keyword: { check_frequency: "weekly" } }, headers: @headers
    assert_redirected_to site_url(@site)
    assert_equal "weekly", @keyword.reload.check_frequency
  end

  test "update keyword disables checking" do
    target = keyword_targets(:apple_iphone18)
    patch site_keyword_url(@site, @keyword),
          params: { keyword: { check_frequency: "daily" }, keyword_target: { tracking_enabled: "0" } },
          headers: @headers
    assert_redirected_to site_url(@site)
    assert_not target.reload.tracking_enabled?
  end

  test "update keyword enables checking" do
    target = keyword_targets(:disabled_keyword)
    keyword = target.keyword
    patch site_keyword_url(sites(:disabled), keyword),
          params: { keyword: { check_frequency: "daily" }, keyword_target: { tracking_enabled: "1" } },
          headers: @headers
    assert_redirected_to site_url(sites(:disabled))
    assert target.reload.tracking_enabled?
  end

  test "check enqueues job" do
    assert_enqueued_with(job: KeywordCheckJob, args: [ @keyword, "us" ]) do
      post check_site_keyword_url(@site, @keyword), headers: @headers
    end
    assert_redirected_to site_url(@site)
  end

  test "import creates a keyword per line" do
    assert_difference("Keyword.count", 3) do
      post import_site_keywords_url(@site), params: {
        keyword: {
          queries: "bulk keyword one\nbulk keyword two\nbulk keyword three",
          check_frequency: "daily",
          search_pages: 2,
          locations: [ "us" ]
        }
      }, headers: @headers
    end
    assert_redirected_to site_url(@site)
    assert_match "3 keywords imported", flash[:notice]
    assert_equal [ 2 ], Keyword.where(query: [ "bulk keyword one", "bulk keyword two", "bulk keyword three" ]).distinct.pluck(:search_pages)
  end

  test "destroy keyword" do
    assert_difference("Keyword.count", -1) do
      delete site_keyword_url(@site, @keyword), headers: @headers
    end
    assert_redirected_to site_url(@site)
  end
end
