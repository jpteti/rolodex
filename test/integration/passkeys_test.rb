require "test_helper"

class PasskeysTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    link = SetupLink.issue(@user)
    register_passkey options_url: setup_options_url(link.token), submit_url: setup_url(link.token), name: "First"
  end

  test "a signed-in user registers another passkey and signs in with it" do
    second = WebAuthn::FakeClient.new(Rails.application.config.x.app_origin)

    assert_difference -> { @user.passkeys.count }, 1 do
      register_passkey options_url: options_passkeys_url, submit_url: passkeys_url, name: "Second", client: second
    end

    get passkeys_url
    assert_select "strong", "First"
    assert_select "strong", "Second"

    delete session_url
    authenticate_with_passkey client: second
    assert_response :success
  end

  test "a user can remove a passkey but not the last one" do
    register_passkey options_url: options_passkeys_url, submit_url: passkeys_url, name: "Second",
      client: WebAuthn::FakeClient.new(Rails.application.config.x.app_origin)
    first, second = @user.passkeys.order(:created_at).to_a

    delete passkey_url(second)
    assert_redirected_to passkeys_url
    assert_not Passkey.exists?(second.id)

    delete passkey_url(first)
    assert_redirected_to passkeys_url
    assert Passkey.exists?(first.id)
    follow_redirect!
    assert_select ".flash", "You cannot remove your only passkey."
  end
end
