require "test_helper"

class ChecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @keyword = keywords(:ruby)
    @headers = auth_headers
  end

  test "get index" do
    get keyword_checks_url(@keyword), headers: @headers
    assert_response :success
    assert_select "table"
  end

  test "shows check history newest first" do
    get keyword_checks_url(@keyword), headers: @headers
    assert_response :success
  end
end
