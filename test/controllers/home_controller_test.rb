require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root page renders with Turbo and Stimulus loaded" do
    sign_in_as users(:owner)
    get root_url
    assert_response :success
    assert_select "script[type=importmap]", text: /@hotwired\/turbo-rails/
    assert_select "script[type=importmap]", text: /@hotwired\/stimulus/
  end
end
