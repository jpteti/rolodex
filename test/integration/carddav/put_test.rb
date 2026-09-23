require "test_helper"

class Carddav::PutTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  IPHONE_CARD = <<~VCF.gsub("\n", "\r\n")
    BEGIN:VCARD
    VERSION:3.0
    PRODID:-//Apple Inc.//iPhone OS 18.0//EN
    N:Curie;Marie;;Dr.;
    FN:Dr. Marie Curie
    ORG:Sorbonne;Physics
    TITLE:Professor
    item1.EMAIL;type=INTERNET;type=pref:marie@example.com
    item1.X-ABLabel:_$!<Other>!$_
    TEL;type=CELL;type=VOICE;type=pref:+33 1 23 45 67 89
    X-SOCIALPROFILE;type=twitter;x-user=mcurie:x-apple:mcurie
    X-ABRELATEDNAMES;type=pref:Pierre Curie
    X-ABUID:5AD380FD-B2DE-4261-BA99-DE1D1DB52FBE:ABPerson
    X-CUSTOM-THING;X-PARAM="a;b":weird\\,value\;kept
    UID:5AD380FD-B2DE-4261-BA99-DE1D1DB52FBE
    END:VCARD
  VCF

  def put_card(name, body, headers = {})
    dav :put, "#{BOOK}#{name}", body: body, headers: { "Content-Type" => "text/vcard; charset=utf-8" }.merge(headers)
  end

  test "PUT with If-None-Match: * creates a contact and returns 201 and an ETag" do
    assert_difference -> { Contact.count }, 1 do
      put_card "5AD380FD.vcf", IPHONE_CARD, "If-None-Match" => "*"
    end
    assert_response :created
    contact = Contact.find_by!(resource_name: "5AD380FD.vcf")
    assert_equal contact.etag, response.headers["ETag"]
    assert_equal "5AD380FD-B2DE-4261-BA99-DE1D1DB52FBE", contact.uid

    sign_in_as users(:owner)
    get contacts_url
    assert_select "#contacts .contact-name", "Dr. Marie Curie"
  end

  test "the stored vCard comes back from GET byte for byte" do
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"

    dav :get, "#{BOOK}curie.vcf"
    assert_equal IPHONE_CARD.b, response.body.b
    assert_includes response.body, %(X-CUSTOM-THING;X-PARAM="a;b":weird\\,value\;kept)
    assert_includes response.body, "X-SOCIALPROFILE;type=twitter;x-user=mcurie:x-apple:mcurie"
  end

  test "If-None-Match: * on an existing contact returns 412" do
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"
    assert_response :precondition_failed
  end

  test "PUT with a matching If-Match updates the contact and its extracted columns" do
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"
    etag = response.headers["ETag"]
    edited = IPHONE_CARD.sub("ORG:Sorbonne;Physics", "ORG:Institut du Radium").sub("item1.EMAIL;type=INTERNET;type=pref:marie@example.com",
      "item1.EMAIL;type=INTERNET;type=pref:marie@radium.example")

    put_card "curie.vcf", edited, "If-Match" => etag
    assert_response :no_content
    assert_not_equal etag, response.headers["ETag"]

    contact = Contact.find_by!(resource_name: "curie.vcf")
    assert_equal "Institut du Radium", contact.organization
    assert_equal [ "marie@radium.example" ], contact.emails
    assert_equal edited, contact.vcard
  end

  test "a stale If-Match returns 412 and changes nothing" do
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"
    contact = Contact.find_by!(resource_name: "curie.vcf")

    put_card "curie.vcf", IPHONE_CARD.sub("Professor", "Director"), "If-Match" => %("stale")
    assert_response :precondition_failed
    assert_equal IPHONE_CARD, contact.reload.vcard

    put_card "missing.vcf", IPHONE_CARD, "If-Match" => contact.etag
    assert_response :precondition_failed
  end

  test "an unconditional PUT creates or replaces" do
    put_card "curie.vcf", IPHONE_CARD
    assert_response :created
    put_card "curie.vcf", IPHONE_CARD.sub("Professor", "Director")
    assert_response :no_content
    assert_includes Contact.find_by!(resource_name: "curie.vcf").vcard, "TITLE:Director"
  end

  test "malformed vCards return 400 and store nothing" do
    assert_no_difference -> { Contact.count } do
      put_card "bad.vcf", "this is not a vcard", "If-None-Match" => "*"
      assert_response :bad_request
      put_card "bad.vcf", "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:x\r\n", "If-None-Match" => "*"
      assert_response :bad_request
      put_card "bad.vcf", "BEGIN:VCARD\r\nFN:\xFF\r\nEND:VCARD\r\n".b, "If-None-Match" => "*"
      assert_response :bad_request
    end
  end

  test "a non-vCard content type returns 415" do
    assert_no_difference -> { Contact.count } do
      put_card "x.vcf", IPHONE_CARD, "Content-Type" => "application/json"
    end
    assert_response :unsupported_media_type
  end

  test "a UID already used by another contact returns 409 no-uid-conflict" do
    put_card "curie.vcf", IPHONE_CARD, "If-None-Match" => "*"
    put_card "copy.vcf", IPHONE_CARD, "If-None-Match" => "*"

    assert_response :conflict
    assert Nokogiri::XML(response.body).at_xpath("//card:no-uid-conflict/d:href[text()='#{BOOK}curie.vcf']", dav_ns)
  end

  test "a vCard without a UID is stored under one derived from the resource name" do
    put_card "no-uid.vcf", "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Anon\r\nN:;Anon;;;\r\nEND:VCARD\r\n", "If-None-Match" => "*"
    assert_response :created
    assert_equal "no-uid", Contact.find_by!(resource_name: "no-uid.vcf").uid
  end

  test "PUT outside the address book is forbidden" do
    put_card "../../other/contacts/x.vcf", IPHONE_CARD
    assert_includes [ 403, 404 ], response.status
    dav :put, "/dav/principals/owner/x.vcf", body: IPHONE_CARD, headers: { "Content-Type" => "text/vcard" }
    assert_response :forbidden
  end

  test "the address book advertises write privileges" do
    dav :propfind, BOOK, body: propfind_body("<d:current-user-privilege-set/>"), headers: { "Depth" => "0" }
    xml = multistatus
    %w[ write write-content bind ].each do |privilege|
      assert xml.at_xpath("//d:privilege/d:#{privilege}", dav_ns), "missing #{privilege}"
    end
  end

  test "a web edit and a device edit each change the getctag" do
    put_card "curie.vcf", IPHONE_CARD
    first = users(:owner).address_book.reload.ctag
    put_card "curie.vcf", IPHONE_CARD.sub("Professor", "Director")
    assert_operator users(:owner).address_book.reload.ctag, :>, first
  end
end
