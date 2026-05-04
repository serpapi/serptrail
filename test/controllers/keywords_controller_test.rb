require "test_helper"

class KeywordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:apple)
    @keyword = keywords(:apple_iphone18)
    @headers = auth_headers
  end

  test "get new" do
    get new_site_keyword_url(@site), headers: @headers
    assert_response :success
  end

  test "create keyword" do
    assert_difference("Keyword.count") do
      assert_enqueued_with(job: KeywordCheckJob) do
        post site_keywords_url(@site), params: { keyword: { query: "new query", check_frequency: "daily", locations: [ "us" ] } }, headers: @headers
      end
    end
    assert_redirected_to site_url(@site)
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

  test "check enqueues job" do
    assert_enqueued_with(job: KeywordCheckJob, args: [@keyword, "us"]) do
      post check_site_keyword_url(@site, @keyword), headers: @headers
    end
    assert_redirected_to site_url(@site)
  end

  test "destroy keyword" do
    assert_difference("Keyword.count", -1) do
      delete site_keyword_url(@site, @keyword), headers: @headers
    end
    assert_redirected_to site_url(@site)
  end
end
