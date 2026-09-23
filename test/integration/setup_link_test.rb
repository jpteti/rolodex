require "test_helper"

class SetupLinkTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @link = SetupLink.issue(@user)
  end

  test "a fresh setup link registers a passkey and signs the user in" do
    get setup_url(@link.token)
    assert_response :success

    assert_difference -> { @user.passkeys.count }, 1 do
      register_passkey options_url: setup_options_url(@link.token), submit_url: setup_url(@link.token), name: "MacBook"
    end
    assert_response :success
    assert_equal root_url, response.parsed_body["redirect_to"]
    assert_equal "MacBook", @user.passkeys.last.name

    get root_url
    assert_response :success
  end

  test "a used setup link shows an error and registers nothing" do
    register_passkey options_url: setup_options_url(@link.token), submit_url: setup_url(@link.token)
    sign_out

    get setup_url(@link.token)
    assert_response :not_found
    assert_select "h1", "This setup link does not work"

    assert_no_difference -> { Passkey.count } do
      post setup_url(@link.token), params: { credential: fake_client.create, name: "Again" }, as: :json
    end
    assert_response :not_found
  end

  test "an expired setup link shows an error and registers nothing" do
    travel SetupLink::VALID_FOR + 1.second do
      get setup_url(@link.token)
      assert_response :not_found

      post setup_options_url(@link.token), params: {}, as: :json
      assert_response :not_found

      assert_no_difference -> { Passkey.count } do
        post setup_url(@link.token), params: { credential: fake_client.create, name: "Late" }, as: :json
      end
      assert_response :not_found
    end
  end

  test "a link that expires between options and submit registers nothing" do
    post setup_options_url(@link.token), params: {}, as: :json
    challenge = response.parsed_body["challenge"]

    travel SetupLink::VALID_FOR + 1.second do
      assert_no_difference -> { Passkey.count } do
        post setup_url(@link.token), params: { credential: fake_client.create(challenge: challenge) }, as: :json
      end
    end
  end

  test "an unknown token shows an error" do
    get setup_url("not-a-real-token")
    assert_response :not_found
  end

  test "a credential signed over the wrong challenge registers nothing and keeps the link usable" do
    post setup_options_url(@link.token), params: {}, as: :json

    assert_no_difference -> { Passkey.count } do
      post setup_url(@link.token), params: { credential: fake_client.create(challenge: WebAuthn::Encoder.new.encode(SecureRandom.random_bytes(32))) }, as: :json
    end
    assert_response :unprocessable_content
    assert SetupLink.find_usable(@link.token)
  end
end
