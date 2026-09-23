require "test_helper"

class Carddav::GroupsTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
  end

  def group_card(name, *members, uid: "GROUP-1")
    lines = [ "BEGIN:VCARD", "VERSION:3.0", "PRODID:-//Apple Inc.//Mac OS X 15.0//EN", "N:#{name}", "FN:#{name}",
              "X-ADDRESSBOOKSERVER-KIND:group" ]
    lines += members.map { |contact| "X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:#{contact.uid}" }
    lines += [ "UID:#{uid}", "END:VCARD" ]
    lines.join("\r\n") + "\r\n"
  end

  def put_group(name, body, headers = {})
    dav :put, "#{BOOK}#{name}", body: body, headers: { "Content-Type" => "text/vcard" }.merge(headers)
  end

  def sync(token)
    dav :report, BOOK, headers: { "Depth" => "1" }, body: <<~XML
      <d:sync-collection xmlns:d="DAV:"><d:sync-token>#{token}</d:sync-token><d:sync-level>1</d:sync-level>
      <d:prop><d:getetag/></d:prop></d:sync-collection>
    XML
    multistatus
  end

  test "a group vCard PUT by a device is stored as a group, not a contact" do
    assert_no_difference -> { Contact.count } do
      assert_difference -> { Group.count }, 1 do
        put_group "GROUP-1.vcf", group_card("Family", @ada, @grace), "If-None-Match" => "*"
      end
    end
    assert_response :created

    group = Group.last
    assert_equal "Family", group.name
    assert_equal [ @ada.uid, @grace.uid ].sort, group.member_uids.sort
    assert_equal response.headers["ETag"], group.etag
  end

  test "groups are served over CardDAV like contacts" do
    body = group_card("Family", @ada)
    put_group "GROUP-1.vcf", body

    dav :propfind, BOOK, body: propfind_body("<d:getetag/>"), headers: { "Depth" => "1" }
    assert_includes multistatus.xpath("//d:href", dav_ns).map(&:text), "#{BOOK}GROUP-1.vcf"

    dav :get, "#{BOOK}GROUP-1.vcf"
    assert_equal body, response.body

    dav :report, BOOK, body: <<~XML
      <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:prop><d:getetag/><card:address-data/></d:prop><d:href>#{BOOK}GROUP-1.vcf</d:href>
      </card:addressbook-multiget>
    XML
    assert_equal body, multistatus.at_xpath("//card:address-data", dav_ns).text
  end

  test "a group changed on one device reaches another through sync and getctag" do
    put_group "GROUP-1.vcf", group_card("Family", @ada)
    token = sync("").at_xpath("/d:multistatus/d:sync-token", dav_ns).text
    ctag = users(:owner).address_book.reload.ctag
    etag = Group.last.etag

    put_group "GROUP-1.vcf", group_card("Family", @ada, @grace), "If-Match" => etag
    assert_response :no_content
    assert_operator users(:owner).address_book.reload.ctag, :>, ctag
    assert_equal [ @ada.uid, @grace.uid ].sort, Group.last.member_uids.sort

    xml = sync(token)
    assert_equal [ "#{BOOK}GROUP-1.vcf" ], xml.xpath("//d:response/d:href", dav_ns).map(&:text)
  end

  test "deleting a group on a device removes it and reports the removal" do
    put_group "GROUP-1.vcf", group_card("Family", @ada)
    token = sync("").at_xpath("/d:multistatus/d:sync-token", dav_ns).text

    dav :delete, "#{BOOK}GROUP-1.vcf"
    assert_response :no_content
    assert_equal 0, Group.count
    assert_not Contact.find(@ada.id).trashed?

    xml = sync(token)
    assert_equal "HTTP/1.1 404 Not Found", xml.at_xpath("//d:response/d:status", dav_ns).text
  end

  test "a contact cannot be turned into a group" do
    dav :put, "#{BOOK}#{@ada.resource_name}", body: group_card("Nope", uid: @ada.uid), headers: { "Content-Type" => "text/vcard" }
    assert_response :bad_request
  end

  test "group vCards never appear in the web contact list" do
    put_group "GROUP-1.vcf", group_card("Family", @ada)
    sign_in_as users(:owner)

    get contacts_url
    assert_equal [ "Grace Hopper", "Ada Lovelace" ], css_select("#contacts .contact-name").map(&:text)
  end

  test "the web UI lists groups and filters contacts by group" do
    put_group "GROUP-1.vcf", group_card("Family", @ada)
    put_group "GROUP-2.vcf", group_card("Work", @grace, uid: "GROUP-2")
    sign_in_as users(:owner)

    get groups_url
    assert_equal [ "Family", "Work" ], css_select("#groups .contact-name").map(&:text)
    assert_select "#groups li", text: /Family\s+1 contact/

    family = Group.find_by!(name: "Family")
    get contacts_url(group: family.id)
    assert_equal [ "Ada Lovelace" ], css_select("#contacts .contact-name").map(&:text)
    assert_select "select[name=group] option[selected]", "Family"

    get contact_url(@ada)
    assert_select "#contact_groups label", text: "Family" do
      assert_select "input[type=checkbox][checked]"
    end
  end

  test "group cards in an imported .vcf become groups" do
    import = users(:owner).address_book.imports.create!(filename: "x.vcf", source: group_card("Imported", @ada, uid: "IMPORTED"))
    import.run

    assert_equal "Imported", Group.find_by!(uid: "IMPORTED").name
    assert_equal 2, Contact.count
  end
end
