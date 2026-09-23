require "test_helper"

class Carddav::SyncCollectionTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace")
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
  end

  def sync(token)
    dav :report, BOOK, headers: { "Depth" => "1" }, body: <<~XML
      <d:sync-collection xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:sync-token>#{token}</d:sync-token>
        <d:sync-level>1</d:sync-level>
        <d:prop><d:getetag/></d:prop>
      </d:sync-collection>
    XML
  end

  def sync_result
    xml = multistatus
    changed = xml.xpath("//d:response[d:propstat]", dav_ns).to_h do |node|
      [ node.at_xpath("d:href", dav_ns).text.delete_prefix(BOOK), node.at_xpath(".//d:getetag", dav_ns).text ]
    end
    removed = xml.xpath("//d:response[d:status='HTTP/1.1 404 Not Found']/d:href", dav_ns).map { |href| href.text.delete_prefix(BOOK) }
    [ changed, removed, xml.at_xpath("/d:multistatus/d:sync-token", dav_ns).text ]
  end

  test "the address book advertises sync-collection and a sync token" do
    dav :propfind, BOOK, body: propfind_body("<d:supported-report-set/>", "<d:sync-token/>"), headers: { "Depth" => "0" }
    xml = multistatus
    assert xml.at_xpath("//d:supported-report/d:report/d:sync-collection", dav_ns)
    assert_match %r{\Ahttp://rolodex.app/ns/sync/\d+\z}, xml.at_xpath("//d:prop/d:sync-token", dav_ns).text
  end

  test "an empty token returns every contact and a token" do
    sync ""
    changed, removed, token = sync_result

    assert_equal [ @ada.resource_name, @grace.resource_name ].sort, changed.keys.sort
    assert_empty removed
    assert_equal users(:owner).address_book.sync_token, token
  end

  test "a token returns only contacts changed since it" do
    sync ""
    _, _, token = sync_result

    @ada.update!(vcard: @ada.vcard.sub("FN:Ada Lovelace", "FN:Ada King"))
    alan = create_contact(given_name: "Alan", family_name: "Turing")

    sync token
    changed, removed, next_token = sync_result
    assert_equal({ @ada.resource_name => @ada.reload.etag, alan.resource_name => alan.etag }, changed)
    assert_empty removed

    sync next_token
    changed, removed, = sync_result
    assert_empty changed
    assert_empty removed
  end

  test "archiving or trashing reports a removal; unarchiving or restoring reports an addition" do
    sync ""
    _, _, token = sync_result

    @ada.archive!
    @grace.trash!
    sync token
    changed, removed, token = sync_result
    assert_empty changed
    assert_equal [ @ada.resource_name, @grace.resource_name ].sort, removed.sort

    @ada.unarchive!
    @grace.restore!
    sync token
    changed, removed, = sync_result
    assert_equal [ @ada.resource_name, @grace.resource_name ].sort, changed.keys.sort
    assert_empty removed
  end

  test "device deletes and permanent deletes report removals" do
    sync ""
    _, _, token = sync_result

    dav :delete, "#{BOOK}#{@ada.resource_name}"
    sync token
    _, removed, token = sync_result
    assert_equal [ @ada.resource_name ], removed

    @ada.reload.destroy!
    sync token
    changed, removed, = sync_result
    assert_empty changed
    assert_empty removed, "a trashed contact is already gone from devices"
  end

  test "a contact changed and then archived since the token is reported once, as removed" do
    sync ""
    _, _, token = sync_result

    @ada.update!(vcard: @ada.vcard.sub("FN:Ada Lovelace", "FN:Ada King"))
    @ada.archive!

    sync token
    changed, removed, = sync_result
    assert_empty changed
    assert_equal [ @ada.resource_name ], removed
  end

  test "edits to archived contacts are not reported" do
    @ada.archive!
    sync ""
    _, _, token = sync_result

    @ada.update!(vcard: @ada.vcard.sub("FN:Ada Lovelace", "FN:Ada King"))
    sync token
    changed, removed, = sync_result
    assert_empty changed
    assert_empty removed
  end

  test "an unknown or future token returns the valid-sync-token error" do
    [ "garbage", "http://rolodex.app/ns/sync/abc", "http://rolodex.app/ns/sync/999999999" ].each do |token|
      sync token
      assert_response :forbidden
      assert Nokogiri::XML(response.body).at_xpath("/d:error/d:valid-sync-token", dav_ns), token
    end
  end

  test "each user's changes stay in their own address book" do
    sync ""
    _, _, token = sync_result

    other = User.create!(username: "other")
    Contact.build_from_fields(other.address_book, { given_name: "Elsewhere" }).save!

    sync token
    changed, removed, = sync_result
    assert_empty changed
    assert_empty removed
  end
end
