require "test_helper"

class TrashTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    sign_in_as users(:owner)
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
  end

  test "CardDAV DELETE returns 204, hides the contact from CardDAV, and changes getctag" do
    ctag = users(:owner).address_book.reload.ctag

    dav :delete, "#{BOOK}#{@ada.resource_name}"
    assert_response :no_content
    assert @ada.reload.trashed?
    assert_operator users(:owner).address_book.reload.ctag, :>, ctag

    dav :get, "#{BOOK}#{@ada.resource_name}"
    assert_response :not_found

    dav :propfind, BOOK, body: propfind_body("<d:getetag/>"), headers: { "Depth" => "1" }
    assert_not_includes multistatus.xpath("//d:href", dav_ns).map(&:text), "#{BOOK}#{@ada.resource_name}"
  end

  test "DELETE honors If-Match" do
    dav :delete, "#{BOOK}#{@ada.resource_name}", headers: { "If-Match" => %("stale") }
    assert_response :precondition_failed
    assert_not @ada.reload.trashed?

    dav :delete, "#{BOOK}#{@ada.resource_name}", headers: { "If-Match" => @ada.etag }
    assert_response :no_content
  end

  test "the Trash lists trashed contacts with their deletion time" do
    travel_to Time.zone.local(2026, 9, 1, 12, 30) do
      dav :delete, "#{BOOK}#{@ada.resource_name}"
    end

    get trashed_contacts_url
    assert_select "#contacts .contact-name", "Ada Lovelace"
    assert_select "#contacts time[datetime='#{Time.zone.local(2026, 9, 1, 12, 30).iso8601}']"
    assert_select "#contacts .contact-name", text: "Grace Hopper", count: 0
  end

  test "trashed contacts are excluded from the main list and the Archive" do
    @grace.archive!
    @grace.trash!
    @ada.trash!

    get contacts_url
    assert_select "#contacts .contact-name", count: 0
    get archived_contacts_url
    assert_select "#contacts .contact-name", count: 0
  end

  test "restoring returns the contact to the main list and to devices" do
    @ada.trash!
    ctag = users(:owner).address_book.reload.ctag

    delete contact_trash_url(@ada)
    assert_redirected_to contact_url(@ada)
    assert_not @ada.reload.trashed?
    assert_operator users(:owner).address_book.reload.ctag, :>, ctag

    get contacts_url
    assert_select "#contacts .contact-name", "Ada Lovelace"

    dav :get, "#{BOOK}#{@ada.resource_name}"
    assert_response :success
  end

  test "DELETE on an archived contact is a 404" do
    @ada.archive!

    dav :delete, "#{BOOK}#{@ada.resource_name}"
    assert_response :not_found
    assert_not @ada.reload.trashed?
  end

  test "DELETE of an unknown resource is a 404" do
    dav :delete, "#{BOOK}nothing.vcf"
    assert_response :not_found
  end
end
