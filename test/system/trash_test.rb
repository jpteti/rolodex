require "application_system_test_case"

class TrashSystemTest < ApplicationSystemTestCase
  test "permanently delete a contact after confirming" do
    contact = Contact.build_from_fields(users(:owner).address_book, { given_name: "Temp", family_name: "Person" }).tap(&:save!)
    contact.trash!
    sign_in_with_new_passkey

    click_on "Trash"
    dismiss_confirm { click_on "Delete permanently" }
    assert_link "Temp Person"

    accept_confirm { click_on "Delete permanently" }
    assert_text "Temp Person was permanently deleted."
    assert_text "The Trash is empty."
    assert_not Contact.exists?(contact.id)
  end
end
