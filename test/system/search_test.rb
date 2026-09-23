require "application_system_test_case"

class SearchSystemTest < ApplicationSystemTestCase
  test "results filter as the user types" do
    book = users(:owner).address_book
    Contact.build_from_fields(book, { given_name: "Ada", family_name: "Lovelace" }).save!
    Contact.build_from_fields(book, { given_name: "Grace", family_name: "Hopper", phones: [ "555-867-5309" ] }).save!
    sign_in_with_new_passkey

    assert_link "Ada Lovelace"
    fill_in "Search contacts", with: "hop"
    assert_no_link "Ada Lovelace"
    assert_link "Grace Hopper"

    fill_in "Search contacts", with: "8675309"
    assert_link "Grace Hopper"

    click_on "Grace Hopper"
    assert_selector "h1", text: "Grace Hopper"
  end
end
