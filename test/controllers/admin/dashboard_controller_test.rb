require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires basic auth" do
    get admin_root_path

    assert_response :unauthorized
  end

  test "allows access with correct credentials" do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin123")

    get admin_root_path, headers: { "HTTP_AUTHORIZATION" => credentials }

    assert_response :success
    assert_includes response.body, "Admin dashboard"
  end
end
