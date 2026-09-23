require "test_helper"

class AppPasswordsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in_as @user
  end

  def basic_auth(username, secret)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(username, secret) }
  end

  test "creating an app password shows the secret once and stores only a digest" do
    post app_passwords_url, params: { app_password: { name: "iPhone" } }
    assert_response :success

    secret = css_select("#app_password_secret").text
    assert_match(/\A[a-z2-9]{5}(-[a-z2-9]{5}){3}\z/, secret)

    app_password = @user.app_passwords.last
    assert_equal "iPhone", app_password.name
    assert_not_includes app_password.attributes.values.map(&:to_s), secret
    assert_equal AppPassword.digest(secret), app_password.secret_digest

    get app_passwords_url
    assert_select "strong", "iPhone"
    assert_select "li", text: /never used/
    assert_not_includes response.body, secret
  end

  test "the list shows last-used time after a CardDAV request" do
    app_password = AppPassword.generate(@user, name: "Mac")

    get carddav_root_url, headers: basic_auth("owner", app_password.secret)
    assert_response :success

    get app_passwords_url
    assert_select "li", text: /last used less than a minute ago/
  end

  test "revoking an app password makes the next CardDAV request return 401" do
    app_password = AppPassword.generate(@user, name: "iPad")

    get carddav_root_url, headers: basic_auth("owner", app_password.secret)
    assert_response :success

    delete app_password_url(app_password)
    assert_redirected_to app_passwords_url

    get carddav_root_url, headers: basic_auth("owner", app_password.secret)
    assert_response :unauthorized
    assert_equal %(Basic realm="Rolodex CardDAV"), response.headers["WWW-Authenticate"]
  end

  test "CardDAV rejects wrong secrets, unknown users, and missing credentials" do
    app_password = AppPassword.generate(@user, name: "iPad")

    get carddav_root_url, headers: basic_auth("owner", "wrong-secret")
    assert_response :unauthorized
    get carddav_root_url, headers: basic_auth("nobody", app_password.secret)
    assert_response :unauthorized
    get carddav_root_url
    assert_response :unauthorized
  end

  test "an app password cannot sign in to another user's account" do
    other = User.create!(username: "other")
    theirs = AppPassword.generate(other, name: "Theirs")

    get carddav_root_url, headers: basic_auth("owner", theirs.secret)
    assert_response :unauthorized
  end

  test "Basic auth over plain HTTP is refused when HTTPS is required" do
    app_password = AppPassword.generate(@user, name: "iPhone")
    Rails.configuration.x.carddav_require_https = true

    get carddav_root_url, headers: basic_auth("owner", app_password.secret)
    assert_response :forbidden

    https!
    get carddav_root_path, headers: basic_auth("owner", app_password.secret)
    assert_response :success
  ensure
    Rails.configuration.x.carddav_require_https = false
  end

  test "the web UI does not accept app passwords" do
    app_password = AppPassword.generate(@user, name: "iPhone")
    sign_out

    get contacts_url, headers: basic_auth("owner", app_password.secret)
    assert_redirected_to new_session_url
  end

  test "production requires HTTPS for CardDAV" do
    production = File.read(Rails.root.join("config/environments/production.rb"))
    assert_match(/config\.x\.carddav_require_https = true/, production)
    assert_match(/config\.assume_ssl = false/, production)
  end
end
