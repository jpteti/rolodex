require "test_helper"

class PasskeyOriginsTest < ActionDispatch::IntegrationTest
  setup do
    @origins = Rails.configuration.x.app_origins
    Rails.configuration.x.app_origins = [ "http://www.example.com", "https://rolodex.test" ]
    @user = users(:owner)
  end

  teardown { Rails.configuration.x.app_origins = @origins }

  test "a passkey registered on a second origin is bound to that host and signs in there" do
    host! "rolodex.test"
    https!
    client = WebAuthn::FakeClient.new("https://rolodex.test")
    link = SetupLink.issue(@user)

    register_passkey options_url: setup_options_url(link.token), submit_url: setup_url(link.token), client: client
    assert_response :success
    assert_equal 1, @user.passkeys.count

    delete session_url
    post options_session_url, params: {}, as: :json
    assert_equal "rolodex.test", response.parsed_body["rpId"]
    authenticate_with_passkey client: client
    assert_response :success
  end

  test "the options name each origin's host as the relying party" do
    post options_session_url, params: {}, as: :json
    assert_equal "www.example.com", response.parsed_body["rpId"]
  end

  test "a passkey registered on one origin does not sign in on another" do
    link = SetupLink.issue(@user)
    register_passkey options_url: setup_options_url(link.token), submit_url: setup_url(link.token)

    reset! # a new browser session; URL helpers pick up the new host
    host! "rolodex.test"
    https!
    authenticate_with_passkey # the fake client signs for www.example.com
    assert_response :unprocessable_content
  end

  test "an origin that is not configured cannot run passkey ceremonies" do
    host! "elsewhere.test"
    post options_session_url, params: {}, as: :json
    assert_response :unprocessable_content
    assert_match "Passkeys are not set up for http://elsewhere.test", response.parsed_body["error"]
  end
end
