require "test_helper"

class Carddav::AddressBookTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    @ada = create_contact(given_name: "Ada", family_name: "Lovelace", emails: [ "ada@example.com" ])
    @grace = create_contact(given_name: "Grace", family_name: "Hopper")
  end

  test "PROPFIND Depth 0 on the address book returns getctag, report set, and address data types" do
    dav :propfind, BOOK, headers: { "Depth" => "0" }, body: propfind_body(
      "<cs:getctag/>", "<d:supported-report-set/>", "<card:supported-address-data/>", "<d:current-user-privilege-set/>"
    )
    xml = multistatus

    assert_equal %("#{users(:owner).address_book.reload.ctag}"), xml.at_xpath("//cs:getctag", dav_ns).text
    assert xml.at_xpath("//d:supported-report/d:report/card:addressbook-multiget", dav_ns)
    assert_equal "3.0", xml.at_xpath("//card:address-data-type", dav_ns)["version"]
    assert xml.at_xpath("//d:current-user-privilege-set/d:privilege/d:read", dav_ns)
    assert_equal 1, xml.xpath("//d:response", dav_ns).size
  end

  test "PROPFIND Depth 1 lists every contact with its ETag" do
    dav :propfind, BOOK, headers: { "Depth" => "1" }, body: propfind_body("<d:getetag/>", "<d:resourcetype/>")
    xml = multistatus

    etags = xml.xpath("//d:response").to_h do |node|
      [ node.at_xpath("d:href", dav_ns).text, node.at_xpath(".//d:getetag", dav_ns)&.text ]
    end
    assert_equal @ada.etag, etags["#{BOOK}#{@ada.resource_name}"]
    assert_equal @grace.etag, etags["#{BOOK}#{@grace.resource_name}"]
    assert_equal 3, etags.size
  end

  test "addressbook-multiget returns vCards and ETags, and 404 for unknown hrefs" do
    body = <<~XML
      <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:prop><d:getetag/><card:address-data/></d:prop>
        <d:href>#{BOOK}#{@ada.resource_name}</d:href>
        <d:href>https://www.example.com#{BOOK}#{@grace.resource_name}</d:href>
        <d:href>#{BOOK}missing.vcf</d:href>
      </card:addressbook-multiget>
    XML
    dav :report, BOOK, body: body, headers: { "Depth" => "1" }
    xml = multistatus

    responses = xml.xpath("//d:response")
    assert_equal 3, responses.size

    ada = responses.find { |r| r.at_xpath("d:href", dav_ns).text.include?(@ada.resource_name) }
    assert_equal @ada.etag, ada.at_xpath(".//d:getetag", dav_ns).text
    assert_equal @ada.vcard, ada.at_xpath(".//card:address-data", dav_ns).text

    grace = responses.find { |r| r.at_xpath("d:href", dav_ns).text.include?(@grace.resource_name) }
    assert_includes grace.at_xpath(".//card:address-data", dav_ns).text, "FN:Grace Hopper"

    missing = responses.find { |r| r.at_xpath("d:href", dav_ns).text.include?("missing.vcf") }
    assert_equal "HTTP/1.1 404 Not Found", missing.at_xpath("d:status", dav_ns).text
  end

  test "addressbook-query returns every contact" do
    body = <<~XML
      <card:addressbook-query xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
        <d:prop><d:getetag/></d:prop>
      </card:addressbook-query>
    XML
    dav :report, BOOK, body: body, headers: { "Depth" => "1" }
    assert_equal 2, multistatus.xpath("//d:propstat[d:status='HTTP/1.1 200 OK']//d:getetag", dav_ns).size
  end

  test "an unsupported REPORT is a 403 supported-report error" do
    dav :report, BOOK, body: %(<d:sync-collection xmlns:d="DAV:"><d:sync-token/></d:sync-collection>)
    assert_response :forbidden
    assert Nokogiri::XML(response.body).at_xpath("//d:error/d:supported-report", dav_ns)
  end

  test "GET returns the stored vCard with its ETag" do
    dav :get, "#{BOOK}#{@ada.resource_name}"
    assert_response :success
    assert_equal @ada.vcard, response.body
    assert_equal @ada.etag, response.headers["ETag"]
    assert_match %r{\Atext/vcard}, response.media_type

    dav :get, "#{BOOK}#{@ada.resource_name}", headers: { "If-None-Match" => @ada.etag }
    assert_response :not_modified
  end

  test "GET of an unknown contact is a 404" do
    dav :get, "#{BOOK}nope.vcf"
    assert_response :not_found
  end

  test "a web edit changes the getctag and the contact ETag" do
    dav :propfind, BOOK, body: propfind_body("<cs:getctag/>"), headers: { "Depth" => "0" }
    old_ctag = multistatus.at_xpath("//cs:getctag", dav_ns).text
    old_etag = @ada.etag

    @ada.update!(vcard: @ada.vcard.sub("FN:Ada Lovelace", "FN:Countess Lovelace"))
    create_contact(given_name: "New")

    dav :propfind, BOOK, body: propfind_body("<cs:getctag/>"), headers: { "Depth" => "0" }
    assert_not_equal old_ctag, multistatus.at_xpath("//cs:getctag", dav_ns).text

    dav :propfind, BOOK, body: propfind_body("<d:getetag/>"), headers: { "Depth" => "1" }
    etags = multistatus.xpath("//d:propstat[d:status='HTTP/1.1 200 OK']//d:getetag", dav_ns).map(&:text)
    assert_not_includes etags, old_etag
    assert_includes etags, @ada.reload.etag
    assert_equal 3, etags.size
  end

  test "PROPPATCH is refused per property" do
    dav :proppatch, BOOK, body: <<~XML
      <d:propertyupdate xmlns:d="DAV:"><d:set><d:prop><d:displayname>New</d:displayname></d:prop></d:set></d:propertyupdate>
    XML
    assert_equal "HTTP/1.1 403 Forbidden", multistatus.at_xpath("//d:status", dav_ns).text
  end
end
