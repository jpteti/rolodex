require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use CHROME_BIN, or a Chrome for Testing build that Selenium Manager downloaded, when no Chrome is installed.
  CHROME_BINARY = ENV["CHROME_BIN"] ||
    Dir.glob(File.expand_path("~/.cache/selenium/chrome/*/*/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing")).max

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.binary = CHROME_BINARY if CHROME_BINARY && !File.exist?("/Applications/Google Chrome.app")
  end

  setup do
    Capybara.enable_aria_label = true

    # Passkeys need a secure context; localhost counts as one.
    Capybara.server_host = "localhost"
    Capybara.server_port = 3111
    Capybara.app_host = "http://localhost:3111"
    WebAuthn.configuration.allowed_origins = [ "http://localhost:3111" ]
    WebAuthn.configuration.rp_id = "localhost"
  end

  teardown do
    @authenticator&.remove!
    WebAuthn.configuration.allowed_origins = [ Rails.application.config.x.app_origin ]
    WebAuthn.configuration.rp_id = URI.parse(Rails.application.config.x.app_origin).host
  end

  private
    # Registers a passkey through a setup link, which also signs the user in.
    def sign_in_with_new_passkey(user = users(:owner))
      visit new_session_path
      add_virtual_authenticator
      visit setup_path(SetupLink.issue(user).token)
      fill_in "Passkey name", with: "Test"
      click_on "Register passkey"
      assert_button "Sign out"
    end

    def add_virtual_authenticator
      options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(
        protocol: :ctap2, transport: :internal, resident_key: true, user_verification: true, user_verified: true
      )
      @authenticator = page.driver.browser.add_virtual_authenticator(options)
    end
end
