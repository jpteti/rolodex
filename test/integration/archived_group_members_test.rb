require "test_helper"

class ArchivedGroupMembersTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    @book = users(:owner).address_book
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
    @family = Group.create_named(@book, "Family")
    @family.add_member(@ada.uid)
    @family.add_member(@grace.uid)
    @work = Group.create_named(@book, "Work")
    @work.add_member(@ada.uid)
  end

  def served_members(group)
    dav :get, "#{BOOK}#{group.resource_name}"
    Vcard::Card.parse(response.body).member_uids
  end

  def sync_token
    dav :propfind, BOOK, body: propfind_body("<d:sync-token/>"), headers: { "Depth" => "0" }
    multistatus.at_xpath("//d:sync-token", dav_ns).text
  end

  def changed_since(token)
    dav :report, BOOK, headers: { "Depth" => "1" }, body: <<~XML
      <d:sync-collection xmlns:d="DAV:"><d:sync-token>#{token}</d:sync-token><d:sync-level>1</d:sync-level>
      <d:prop><d:getetag/></d:prop></d:sync-collection>
    XML
    multistatus.xpath("//d:response/d:href", dav_ns).map { |href| href.text.delete_prefix(BOOK) }
  end

  test "group vCards served over CardDAV omit archived members, and their ETags change" do
    etag = @family.reload.etag
    token = sync_token

    @ada.archive!

    assert_equal [ @grace.uid ], served_members(@family)
    assert_empty served_members(@work)
    assert_not_equal etag, @family.reload.etag
    assert_equal response.headers["ETag"], @work.reload.etag
    assert_equal [ @ada.resource_name, @family.resource_name, @work.resource_name ].sort, changed_since(token).sort

    dav :report, BOOK, body: <<~XML
      <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:prop><card:address-data/></d:prop><d:href>#{BOOK}#{@family.resource_name}</d:href>
      </card:addressbook-multiget>
    XML
    assert_not_includes multistatus.at_xpath("//card:address-data", dav_ns).text, @ada.uid
  end

  test "a device PUT of a group keeps the memberships of archived contacts" do
    @ada.archive!
    dav :get, "#{BOOK}#{@family.resource_name}"
    served = response.body
    etag = response.headers["ETag"]

    # The device renames the group; its copy has no archived members.
    dav :put, "#{BOOK}#{@family.resource_name}", body: served.gsub("Family", "Relatives"),
      headers: { "Content-Type" => "text/vcard", "If-Match" => etag }
    assert_response :no_content

    @family.reload
    assert_equal "Relatives", @family.name
    assert_equal [ @ada.uid, @grace.uid ].sort, @family.member_uids.sort
    assert_equal [ @grace.uid ], served_members(@family)
  end

  test "a device can still remove a visible member" do
    @ada.archive!
    dav :get, "#{BOOK}#{@family.resource_name}"
    without_grace = response.body.sub("X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:#{@grace.uid}\r\n", "")

    dav :put, "#{BOOK}#{@family.resource_name}", body: without_grace, headers: { "Content-Type" => "text/vcard" }
    assert_equal [ @ada.uid ], @family.reload.member_uids
  end

  test "unarchiving restores the contact to every group, on the web and on devices" do
    @ada.archive!
    token = sync_token

    @ada.unarchive!

    assert_equal [ @ada.uid, @grace.uid ].sort, served_members(@family).sort
    assert_equal [ @ada.uid ], served_members(@work)
    assert_equal [ @ada.resource_name, @family.resource_name, @work.resource_name ].sort, changed_since(token).sort

    sign_in_as users(:owner)
    get contacts_url(group: @work.id)
    assert_equal [ "Ada Lovelace" ], css_select("#contacts .contact-name").map(&:text)
  end

  test "the web UI shows an archived contact's remembered groups" do
    @ada.archive!
    sign_in_as users(:owner)

    get contact_url(@ada)
    assert_select "#contact_groups input[type=checkbox][checked]", 2
    assert_select "p", text: /remembers the groups/

    get contacts_url(group: @family.id)
    assert_equal [ "Grace Hopper" ], css_select("#contacts .contact-name").map(&:text)
  end

  test "trashed members are omitted too" do
    @grace.trash!
    assert_equal [ @ada.uid ], served_members(@family)
  end
end
