require "test_helper"

class SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = sites(:example)
    @headers = auth_headers
  end

  test "requires authentication" do
    get sites_url
    assert_response :unauthorized
  end

  test "get index" do
    get sites_url, headers: @headers
    assert_response :success
    assert_select "h1", "Sites"
  end

  test "get show" do
    get site_url(@site), headers: @headers
    assert_response :success
    assert_select "h1", @site.name
    assert_select ".card-grid"
  end

  test "get table" do
    get table_site_url(@site), headers: @headers
    assert_response :success
    assert_select "table"
  end

  test "get new" do
    get new_site_url, headers: @headers
    assert_response :success
  end

  test "create site" do
    assert_difference("Site.count") do
      post sites_url, params: { site: { name: "New", domain: "new.com", tracking_enabled: true } }, headers: @headers
    end
    assert_redirected_to site_url(Site.last)
  end

  test "get edit" do
    get edit_site_url(@site), headers: @headers
    assert_response :success
  end

  test "update site" do
    patch site_url(@site), params: { site: { name: "Updated" } }, headers: @headers
    assert_redirected_to site_url(@site)
    assert_equal "Updated", @site.reload.name
  end

  test "destroy site" do
    assert_difference("Site.count", -1) do
      delete site_url(@site), headers: @headers
    end
    assert_redirected_to sites_url
  end
end
