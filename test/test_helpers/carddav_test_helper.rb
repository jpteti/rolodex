module CarddavTestHelper
  def carddav_credentials(user = users(:owner))
    @app_password ||= AppPassword.generate(user, name: "Test device")
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, @app_password.secret)
  end

  def dav(method, path, body: nil, headers: {})
    process method, path, params: body, headers: {
      "Authorization" => carddav_credentials,
      "Content-Type" => "application/xml; charset=utf-8"
    }.merge(headers)
  end

  def multistatus
    assert_equal 207, response.status, response.body
    Nokogiri::XML(response.body)
  end

  def dav_ns
    { "d" => "DAV:", "card" => "urn:ietf:params:xml:ns:carddav", "cs" => "http://calendarserver.org/ns/" }
  end

  def propfind_body(*props)
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <d:propfind xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav" xmlns:cs="http://calendarserver.org/ns/">
        <d:prop>#{props.join}</d:prop>
      </d:propfind>
    XML
  end

  def create_contact(**fields)
    Contact.build_from_fields(users(:owner).address_book, fields).tap(&:save!)
  end
end
