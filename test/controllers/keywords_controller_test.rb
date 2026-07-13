require "test_helper"

class KeywordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = auth_headers
  end

  test "get index" do
    get keywords_url, headers: @headers
    assert_response :success
    assert_select "h1", "Keywords"
  end

  test "show separates multi-page search results" do
    keyword = keywords(:bestbuy_iphone18)

    get keyword_url(keyword), headers: @headers

    assert_response :success
    assert_select ".organic-result", count: 20
    assert_select ".organic-results-page-divider", count: 1, text: "Page 2"
  end

  test "get new" do
    get new_keyword_url, headers: @headers
    assert_response :success
    assert_select "input[type='range'][name='keyword[search_pages]'][min='1'][max='5']"
    assert_select ".search-depth-value", text: "1 page"
  end

  test "create keyword without sites" do
    assert_difference("Keyword.count") do
      assert_no_difference("KeywordTarget.count") do
        assert_enqueued_with(job: KeywordCheckJob) do
          post keywords_url, params: {
            keyword: {
              query: "global targetless keyword",
              check_frequency: "daily",
              locations: [ "us" ],
              site_ids: [ "" ]
            }
          }, headers: @headers
        end
      end
    end

    keyword = Keyword.find_by!(query: "global targetless keyword")
    assert_redirected_to keyword_url(keyword)
  end

  test "create keyword with selected sites" do
    assert_difference("Keyword.count") do
      assert_difference("KeywordTarget.count", 2) do
        post keywords_url, params: {
          keyword: {
            query: "global tracked keyword",
            check_frequency: "weekly",
            search_pages: 3,
            locations: [ "us", "gb" ],
            site_ids: [ sites(:apple).id, sites(:bestbuy).id ]
          }
        }, headers: @headers
      end
    end

    keyword = Keyword.find_by!(query: "global tracked keyword")
    assert_equal [ sites(:apple).id, sites(:bestbuy).id ].sort, keyword.keyword_targets.pluck(:site_id).sort
    assert_equal 3, keyword.search_pages
    assert_redirected_to keyword_url(keyword)
  end

  test "update keyword site selections" do
    keyword = keywords(:apple_iphone18)

    patch keyword_url(keyword), params: {
      keyword: {
        query: keyword.query,
        check_frequency: keyword.check_frequency,
        locations: keyword.locations,
        site_ids: [ sites(:bestbuy).id ]
      }
    }, headers: @headers

    assert_redirected_to keyword_url(keyword)
    assert_equal [ sites(:bestbuy).id ], keyword.keyword_targets.reload.pluck(:site_id)
  end

  test "check enqueues checks for each location" do
    keyword = keywords(:apple_iphone18)

    assert_enqueued_with(job: KeywordCheckJob, args: [ keyword, "us" ]) do
      post check_keyword_url(keyword), headers: @headers
    end
    assert_redirected_to keyword_url(keyword)
  end
end
