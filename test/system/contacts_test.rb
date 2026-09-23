require "application_system_test_case"

class ContactsSystemTest < ApplicationSystemTestCase
  test "create a contact and see it in the list" do
    sign_in_with_new_passkey

    click_on "New contact"
    fill_in "First name", with: "Katherine"
    fill_in "Last name", with: "Johnson"
    fill_in "Organization", with: "NASA"
    within("#emails") do
      click_on "Add email"
      all("input[type=email]").last.fill_in with: "kj@nasa.example"
      click_on "Add email"
      all("input[type=email]").last.fill_in with: "katherine@example.com"
    end
    within("#phones") do
      click_on "Add phone"
      all("input[type=tel]").last.fill_in with: "555-0199"
    end
    click_on "Create contact"

    assert_text "Contact created."
    assert_selector "h1", text: "Katherine Johnson"
    assert_link "katherine@example.com"

    click_on "← Contacts"
    assert_link "Katherine Johnson"
  end
end
