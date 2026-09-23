require "application_system_test_case"

class PasskeySignInTest < ApplicationSystemTestCase
  test "register a passkey from a setup link, sign out, and sign back in" do
    visit root_path # load the origin before attaching the authenticator
    add_virtual_authenticator

    link = SetupLink.issue(users(:owner))
    visit setup_path(link.token)
    fill_in "Passkey name", with: "Laptop"
    click_on "Register passkey"

    assert_link "Passkeys"
    assert_equal [ "Laptop" ], users(:owner).passkeys.pluck(:name)

    click_on "Sign out"
    assert_text "Signed out."

    click_on "Sign in with a passkey"
    assert_link "Passkeys"
    assert_current_path root_path
  end
end
