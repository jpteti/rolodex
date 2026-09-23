require "test_helper"

class ArchiveTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    sign_in_as users(:owner)
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace", organization: "Engines", emails: [ "ada@example.com" ], phones: [ "555-0100" ])
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
  end

  test "archiving moves a contact from the main list to the Archive section" do
    get contact_url(@ada)
    assert_select "button", "Archive"

    post contact_archive_url(@ada)
    assert_redirected_to contact_url(@ada)
    assert @ada.reload.archived?

    get contacts_url
    assert_select "#contacts .contact-name", text: "Ada Lovelace", count: 0
    assert_select "#contacts .contact-name", "Grace Hopper"

    get archived_contacts_url
    assert_select "#contacts .contact-name", text: "Ada Lovelace"
    assert_select "#contacts .contact-name", text: "Grace Hopper", count: 0
  end

  test "archived contacts stay viewable with all fields" do
    vcard = @ada.vcard
    @ada.archive!

    get contact_url(@ada)
    assert_response :success
    assert_select "h1", "Ada Lovelace"
    assert_select "dd", "Engines"
    assert_select "dd a", "ada@example.com"
    assert_select "dd a", "555-0100"
    assert_select "button", "Unarchive"
    assert_equal vcard, @ada.reload.vcard
  end

  test "archived contacts disappear from PROPFIND, multiget, and GET, and getctag changes" do
    ctag = users(:owner).address_book.reload.ctag
    post contact_archive_url(@ada)
    assert_operator users(:owner).address_book.reload.ctag, :>, ctag

    dav :propfind, BOOK, body: propfind_body("<d:getetag/>"), headers: { "Depth" => "1" }
    hrefs = multistatus.xpath("//d:response/d:href", dav_ns).map(&:text)
    assert_not_includes hrefs, "#{BOOK}#{@ada.resource_name}"
    assert_includes hrefs, "#{BOOK}#{@grace.resource_name}"

    dav :report, BOOK, body: <<~XML
      <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:prop><d:getetag/><card:address-data/></d:prop>
        <d:href>#{BOOK}#{@ada.resource_name}</d:href>
      </card:addressbook-multiget>
    XML
    assert_equal "HTTP/1.1 404 Not Found", multistatus.at_xpath("//d:response/d:status", dav_ns).text

    dav :get, "#{BOOK}#{@ada.resource_name}"
    assert_response :not_found
  end

  test "unarchiving returns the contact to the main list and to devices" do
    @ada.archive!
    ctag = users(:owner).address_book.reload.ctag

    delete contact_archive_url(@ada)
    assert_not @ada.reload.archived?
    assert_operator users(:owner).address_book.reload.ctag, :>, ctag

    get contacts_url
    assert_select "#contacts .contact-name", text: "Ada Lovelace"

    dav :get, "#{BOOK}#{@ada.resource_name}"
    assert_response :success
    assert_equal @ada.vcard, response.body
  end
end
