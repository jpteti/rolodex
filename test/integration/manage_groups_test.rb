require "test_helper"

class ManageGroupsTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    sign_in_as users(:owner)
    @book = users(:owner).address_book
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
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
    multistatus.xpath("//d:response", dav_ns).map do |node|
      [ node.at_xpath("d:href", dav_ns).text.delete_prefix(BOOK), node.at_xpath("d:status", dav_ns)&.text ]
    end
  end

  test "create a group that devices receive as an Apple group vCard" do
    token = sync_token
    post groups_url, params: { group: { name: "Book club" } }
    assert_redirected_to groups_url

    group = @book.groups.find_by!(name: "Book club")
    card = Vcard::Card.parse(group.vcard)
    assert card.group?
    assert_equal "Book club", card.value("FN")
    assert_equal [ [ group.resource_name, nil ] ], changed_since(token)

    dav :get, "#{BOOK}#{group.resource_name}"
    assert_includes response.body, "X-ADDRESSBOOKSERVER-KIND:group"
  end

  test "a blank group name is an error" do
    assert_no_difference -> { Group.count } do
      post groups_url, params: { group: { name: " " } }
    end
    assert_response :unprocessable_content
  end

  test "rename a group, keeping its members and other properties" do
    group = Group.create_named(@book, "Old")
    group.add_member(@ada.uid)
    group.update!(vcard: group.vcard.sub("END:VCARD", "X-CUSTOM:kept\r\nEND:VCARD"))
    token = sync_token

    patch group_url(group), params: { group: { name: "New" } }
    assert_redirected_to groups_url

    group.reload
    assert_equal "New", group.name
    assert_equal "New", group.card.value("N")
    assert_equal [ @ada.uid ], group.member_uids
    assert_equal "kept", group.card.value("X-CUSTOM")
    assert_equal [ [ group.resource_name, nil ] ], changed_since(token)
  end

  test "delete a group without touching its contacts" do
    group = Group.create_named(@book, "Temp")
    group.add_member(@ada.uid)
    token = sync_token

    delete group_url(group)
    assert_not Group.exists?(group.id)
    assert Contact.exists?(@ada.id)
    assert_equal [ [ group.resource_name, "HTTP/1.1 404 Not Found" ] ], changed_since(token)
  end

  test "add and remove a contact's groups from the contact page" do
    family = Group.create_named(@book, "Family")
    work = Group.create_named(@book, "Work")
    work.add_member(@ada.uid)

    get contact_url(@ada)
    assert_select "#contact_groups input[type=checkbox]", 2
    token = sync_token

    patch contact_groups_url(@ada), params: { group_ids: [ family.id ] }
    assert_redirected_to contact_url(@ada)

    assert_equal [ @ada.uid ], family.reload.member_uids
    assert_empty work.reload.member_uids
    assert_includes family.card.all("X-ADDRESSBOOKSERVER-MEMBER").map(&:value), "urn:uuid:#{@ada.uid}"
    assert_equal [ family.resource_name, work.resource_name ].sort, changed_since(token).map(&:first).sort

    get contacts_url(group: family.id)
    assert_equal [ "Ada Lovelace" ], css_select("#contacts .contact-name").map(&:text)
  end

  test "saving unchanged groups does not touch the group vCards" do
    family = Group.create_named(@book, "Family")
    family.add_member(@ada.uid)
    vcard = family.reload.vcard
    token = sync_token

    patch contact_groups_url(@ada), params: { group_ids: [ family.id ] }
    assert_equal vcard, family.reload.vcard
    assert_empty changed_since(token)
  end
end
