require "test_helper"

class ChecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @keyword = keywords(:apple_iphone18)
    @site = @keyword.site
    @headers = auth_headers
  end

  test "get index" do
    get site_keyword_checks_url(@site, @keyword), headers: @headers
    assert_response :success
    assert_select "table"
  end

  test "shows check history newest first" do
    get site_keyword_checks_url(@site, @keyword), headers: @headers
    assert_response :success
  end
end
