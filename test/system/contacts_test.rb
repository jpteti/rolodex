require "application_system_test_case"

class ContactsSystemTest < ApplicationSystemTestCase
  test "create a contact and see it in the list" do
    sign_in_with_new_passkey

    click_on "New contact"
    fill_in "First name", with: "Katherine"
    fill_in "Last name", with: "Johnson"
    fill_in "Organization", with: "NASA"
    all("input[type=email]")[0].fill_in with: "kj@nasa.example"
    all("input[type=email]")[1].fill_in with: "katherine@example.com"
    all("input[type=tel]")[0].fill_in with: "555-0199"
    click_on "Create contact"

    assert_text "Contact created."
    assert_selector "h1", text: "Katherine Johnson"
    assert_link "katherine@example.com"

    click_on "← Contacts"
    assert_link "Katherine Johnson"
  end
end
