require "test_helper"

class TenantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = auth_headers
    @tenant = tenants(:default)
  end

  test "settings shows API key fields" do
    get settings_url, headers: @headers

    assert_response :success
    assert_select "input[name='tenant[serpapi_key]']"
    assert_select "input[name='tenant[openai_api_key]']"
    assert_select ".settings-layout > #serpapi-credit-estimate.card" do
      assert_select "h2.card-title", text: "SerpApi credit estimate"
      assert_select ".card-stat-label", text: "Estimated monthly credits"
      assert_select ".card-stat-label", text: "Keywords being checked"
      assert_select "p", text: /Each page costs one SerpApi credit/
    end
  end

  test "updates API keys" do
    patch settings_url,
      params: { tenant: { serpapi_key: "new_serpapi_key", openai_api_key: "new_openai_key" } },
      headers: @headers

    assert_redirected_to settings_path
    @tenant.reload
    assert_equal "new_serpapi_key", @tenant.serpapi_key
    assert_equal "new_openai_key", @tenant.openai_api_key
  end
end
