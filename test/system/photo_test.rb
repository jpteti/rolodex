require "application_system_test_case"

class PhotoSystemTest < ApplicationSystemTestCase
  test "upload a photo and see it on the list and detail pages" do
    contact = Contact.build_from_fields(users(:owner).address_book, { given_name: "Hedy", family_name: "Lamarr" }).tap(&:save!)
    path = Rails.root.join("tmp/system-photo.png")
    (Vips::Image.black(900, 900, bands: 3) + [ 60, 110, 200 ]).cast(:uchar).write_to_file(path.to_s)
    sign_in_with_new_passkey

    assert_selector ".avatar--initials", text: "HL"
    visit edit_contact_path(contact)
    attach_file "Photo", path
    click_on "Upload photo"
    assert_text "Photo saved."
    assert_button "Remove photo"

    click_on "← Hedy Lamarr"
    assert_selector "img.avatar--large"
    assert page.evaluate_script("document.querySelector('img.avatar--large').naturalWidth") == 512
    take_screenshot
    click_on "← Contacts"
    assert_selector "#contacts img.avatar"
  end
end
