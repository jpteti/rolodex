require "test_helper"

class Carddav::DiscoveryTest < ActionDispatch::IntegrationTest
  test "OPTIONS advertises CardDAV" do
    dav :options, "/dav/addressbooks/owner/contacts/"
    assert_response :success
    assert_equal "1, 3, addressbook", response.headers["DAV"]
    assert_includes response.headers["Allow"], "PROPFIND"
    assert_includes response.headers["Allow"], "REPORT"
  end

  test "/.well-known/carddav redirects to the DAV root for any method" do
    process :propfind, "/.well-known/carddav"
    assert_response :moved_permanently
    assert_equal "http://www.example.com/dav/", response.headers["Location"]

    get "/.well-known/carddav"
    assert_response :moved_permanently
  end

  test "PROPFIND on the root and on / returns the current user principal" do
    [ "/dav/", "/" ].each do |path|
      dav :propfind, path, body: propfind_body("<d:current-user-principal/>"), headers: { "Depth" => "0" }
      assert_equal "/dav/principals/owner/", multistatus.at_xpath("//d:current-user-principal/d:href", dav_ns).text
    end
  end

  test "PROPFIND on the principal returns the address book home" do
    dav :propfind, "/dav/principals/owner/",
      body: propfind_body("<card:addressbook-home-set/>", "<d:displayname/>", "<d:resourcetype/>", "<d:principal-URL/>"),
      headers: { "Depth" => "0" }
    xml = multistatus

    assert_equal "/dav/addressbooks/owner/", xml.at_xpath("//card:addressbook-home-set/d:href", dav_ns).text
    assert_equal "owner", xml.at_xpath("//d:displayname", dav_ns).text
    assert xml.at_xpath("//d:resourcetype/d:principal", dav_ns)
    assert_equal "/dav/principals/owner/", xml.at_xpath("//d:principal-URL/d:href", dav_ns).text
  end

  test "PROPFIND Depth 1 on the home lists the address book" do
    dav :propfind, "/dav/addressbooks/owner/", body: propfind_body("<d:resourcetype/>", "<d:displayname/>", "<cs:getctag/>"),
      headers: { "Depth" => "1" }
    xml = multistatus

    hrefs = xml.xpath("//d:response/d:href", dav_ns).map(&:text)
    assert_equal [ "/dav/addressbooks/owner/", "/dav/addressbooks/owner/contacts/" ], hrefs

    book = xml.xpath("//d:response").find { |r| r.at_xpath("d:href", dav_ns).text.end_with?("contacts/") }
    assert book.at_xpath(".//d:resourcetype/card:addressbook", dav_ns)
    assert book.at_xpath(".//d:resourcetype/d:collection", dav_ns)
    assert_equal "Contacts", book.at_xpath(".//d:displayname", dav_ns).text
  end

  test "unknown properties come back in a 404 propstat" do
    dav :propfind, "/dav/principals/owner/", body: propfind_body("<d:displayname/>", %(<x:made-up xmlns:x="urn:example"/>)),
      headers: { "Depth" => "0" }
    xml = multistatus

    missing = xml.xpath("//d:propstat[d:status='HTTP/1.1 404 Not Found']/d:prop/*", dav_ns)
    assert_equal [ [ "urn:example", "made-up" ] ], missing.map { |node| [ node.namespace.href, node.name ] }
  end

  test "an empty PROPFIND body means allprop" do
    dav :propfind, "/dav/principals/owner/", headers: { "Depth" => "0" }
    assert multistatus.at_xpath("//card:addressbook-home-set", dav_ns)
  end

  test "other users' paths are not found" do
    User.create!(username: "someone")
    dav :propfind, "/dav/addressbooks/someone/contacts/", body: propfind_body("<d:displayname/>")
    assert_response :not_found
  end

  test "malformed XML is a 400" do
    dav :propfind, "/dav/principals/owner/", body: "<d:propfind"
    assert_response :bad_request
  end

  test "requests without valid credentials get 401 with a Basic challenge" do
    process :propfind, "/dav/principals/owner/"
    assert_response :unauthorized
    assert_equal %(Basic realm="Rolodex CardDAV"), response.headers["WWW-Authenticate"]

    process :propfind, "/", headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("owner", "nope") }
    assert_response :unauthorized
    assert_equal %(Basic realm="Rolodex CardDAV"), response.headers["WWW-Authenticate"]
  end
end
