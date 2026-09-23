require "application_system_test_case"

class EditContactTest < ApplicationSystemTestCase
  test "edit a contact, adding and removing repeated fields in place" do
    contact = Contact.build_from_fields(users(:owner).address_book,
      { given_name: "Mary", family_name: "Jackson", emails: [ "mary@example.com" ], phones: [ "555-0001", "555-0002" ] }).tap(&:save!)
    sign_in_with_new_passkey

    visit edit_contact_path(contact)
    page.execute_script("window.pageMarker = 'still here'")

    within("#emails") do
      click_on "Add email"
      all("input[type=email]").last.fill_in with: "mjackson@nasa.example"
      all("input[list=labels-emails]").last.fill_in with: "work"
    end
    within("#phones") { all("button", text: "Remove").first.click }
    within("#addresses") do
      click_on "Add address"
      fill_in "Street", with: "1 Langley Blvd"
      fill_in "City", with: "Hampton"
      fill_in "State", with: "VA"
    end
    fill_in "Job title", with: "Engineer"
    fill_in "Birthday", with: "1921-04-09"
    assert_equal "still here", page.evaluate_script("window.pageMarker")
    take_screenshot

    click_on "Save"
    assert_text "Contact saved."

    card = Vcard::Card.parse(contact.reload.vcard)
    assert_equal [ "mary@example.com", "mjackson@nasa.example" ], card.all("EMAIL").map(&:text)
    assert_equal "work", card.label_for(card.all("EMAIL").last)
    assert_equal [ "555-0002" ], card.all("TEL").map(&:text)
    assert_equal "Hampton", card["ADR"].components[3]
    assert_equal "Engineer", card.value("TITLE")
    assert_equal "1921-04-09", card.value("BDAY")
    assert_text "1 Langley Blvd"
  end

  test "delete moves the contact to the Trash" do
    contact = Contact.build_from_fields(users(:owner).address_book, { given_name: "Dorothy", family_name: "Vaughan" }).tap(&:save!)
    sign_in_with_new_passkey

    visit contact_path(contact)
    click_on "Delete"
    assert_text "Dorothy Vaughan moved to the Trash."
    assert contact.reload.trashed?

    click_on "Trash"
    assert_link "Dorothy Vaughan"
  end
end
