require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    link = SetupLink.issue(@user)
    register_passkey options_url: setup_options_url(link.token), submit_url: setup_url(link.token)
    sign_out
  end

  test "anonymous visitors are redirected to sign in" do
    [ root_url, passkeys_url ].each do |url|
      get url
      assert_redirected_to new_session_url
    end
  end

  test "sign-in and setup pages are reachable anonymously" do
    get new_session_url
    assert_response :success

    get setup_url(SetupLink.issue(@user).token)
    assert_response :success
  end

  test "signing in with a registered passkey starts a session and signing out ends it" do
    authenticate_with_passkey
    assert_response :success

    get root_url
    assert_response :success
    assert @user.passkeys.first.reload.last_used_at

    delete session_url
    assert_redirected_to new_session_url

    get root_url
    assert_redirected_to new_session_url
  end

  test "signing in returns to the page the visitor asked for" do
    get passkeys_url
    authenticate_with_passkey
    assert_equal passkeys_url, response.parsed_body["redirect_to"]
  end

  test "an unregistered passkey cannot sign in" do
    stranger = WebAuthn::FakeClient.new(Rails.application.config.x.app_origin)
    stranger.create # a credential the server never saw
    authenticate_with_passkey client: stranger
    assert_response :unprocessable_content

    get root_url
    assert_redirected_to new_session_url
  end
end
