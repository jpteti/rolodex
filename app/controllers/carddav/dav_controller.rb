# Serves the CardDAV tree: OPTIONS, PROPFIND, PROPPATCH, REPORT, and GET.
class Carddav::DavController < Carddav::BaseController
  DAV_HEADER = "1, 3, addressbook".freeze
  XML_TYPE = "application/xml; charset=utf-8".freeze

  rescue_from Dav::BadRequest do |error|
    render plain: "#{error.message}\n", status: :bad_request
  end

  def serve
    case request.request_method
    when "OPTIONS" then options
    when "PROPFIND" then propfind
    when "PROPPATCH" then proppatch
    when "REPORT" then report
    when "GET", "HEAD" then show
    when "PUT" then put
    when "DELETE" then delete
    else method_not_allowed
    end
  end

  private
    def options
      response.headers["DAV"] = DAV_HEADER
      response.headers["Allow"] = allowed_methods.join(", ")
      head :ok
    end

    def propfind
      resource = resolve(request.path) or return head(:not_found)
      requested = Dav.requested_properties(Dav.parse_xml(request.raw_post)&.root)

      multistatus = Dav::Multistatus.new
      resources = [ resource ]
      resources += resource.children if depth >= 1 && resource.collection?
      resources.each { |each| add_properties(multistatus, each, requested) }

      render_multistatus multistatus
    end

    # Properties are read-only; answer each requested change with 403 so clients carry on.
    def proppatch
      resource = resolve(request.path) or return head(:not_found)
      document = Dav.parse_xml(request.raw_post) or raise Dav::BadRequest, "Missing body"
      properties = document.xpath("//d:prop/*", "d" => Dav::DAV).map { |element| Dav.prop(element.namespace&.href, element.name) }

      multistatus = Dav::Multistatus.new
      multistatus.add(resource.href, missing: properties, missing_status: "HTTP/1.1 403 Forbidden")
      render_multistatus multistatus
    end

    def report
      resource = resolve(request.path) or return head(:not_found)
      document = Dav.parse_xml(request.raw_post) or raise Dav::BadRequest, "Missing body"
      root = document.root

      return render_report_unsupported unless resource.is_a?(Carddav::AddressBookCollection)

      case [ root.namespace&.href, root.name ]
      in [ Dav::CARDDAV, "addressbook-multiget" ] then addressbook_multiget(resource, root)
      in [ Dav::CARDDAV, "addressbook-query" ] then addressbook_query(resource, root)
      in [ Dav::DAV, "sync-collection" ] then sync_collection(resource, root)
      else render_report_unsupported
      end
    end

    def show
      resource = resolve(request.path) or return head(:not_found)
      return render(plain: "Rolodex CardDAV\n") if resource.collection?

      record = resource.record
      response.headers["ETag"] = record.etag
      response.headers["Last-Modified"] = record.updated_at.httpdate
      return head(:not_modified) if request.headers["If-None-Match"] == record.etag

      send_data record.served_vcard, type: "text/vcard; charset=utf-8", disposition: :inline
    end

    def method_not_allowed
      response.headers["Allow"] = allowed_methods.join(", ")
      head :method_not_allowed
    end

    def allowed_methods
      %w[ OPTIONS GET HEAD PUT DELETE PROPFIND PROPPATCH REPORT ]
    end

    # Creates or replaces a contact with the vCard in the body, honoring If-Match and If-None-Match.
    def put
      resource_name = put_target(request.path) or return head(:forbidden)
      existing = current_user.address_book.device_resource(resource_name)

      return head(:precondition_failed) unless put_preconditions_met?(existing)
      return head(:unsupported_media_type) unless vcard_media_type?
      return head(:payload_too_large) if request.raw_post.bytesize > Contact::MAX_VCARD_BYTES

      result = current_user.address_book.store_from_device(resource_name, request.raw_post, existing: existing)
      case result
      in { record: }
        response.headers["ETag"] = record.etag
        head(existing ? :no_content : :created)
      in { error: :invalid, message: }
        render plain: "#{message}\n", status: :bad_request
      in { error: :uid_conflict, resource_name: taken }
        render_precondition_error "no-uid-conflict", Dav::CARDDAV, :conflict, href: Carddav::Paths.card(current_user, taken)
      in { error: :hidden_resource }
        head :conflict
      end
    end

    # Deleting a contact on a device moves it to the Trash; deleting a group removes it.
    # Archived contacts are invisible to devices, so 404.
    def delete
      resource = resolve(request.path)
      return head(:not_found) unless resource.is_a?(Carddav::CardResource)

      record = resource.record
      if_match = request.headers["If-Match"]
      return head(:precondition_failed) if if_match.present? && if_match != "*" && if_match != record.etag

      record.is_a?(Contact) ? record.trash! : record.destroy!
      head :no_content
    end

    def put_preconditions_met?(existing)
      if_match = request.headers["If-Match"]
      if_none_match = request.headers["If-None-Match"]

      return false if if_none_match == "*" && existing
      return false if if_match.present? && (existing.nil? || (if_match != "*" && if_match != existing.etag))
      true
    end

    def vcard_media_type?
      request.media_type.in?(%w[ text/vcard text/x-vcard text/directory ]) || request.media_type.blank?
    end

    # Resolves a PUT target inside the user's address book. Returns the resource name or nil.
    def put_target(path)
      segments = URI::DEFAULT_PARSER.unescape(path).split("/").reject(&:empty?)
      segments.shift if segments.first == "dav"

      case segments
      in [ "addressbooks", username, "contacts", resource_name ] if own?(username) then resource_name
      else nil
      end
    end

    def render_precondition_error(name, namespace, status, href: nil)
      body = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml["d"].error("xmlns:d" => Dav::DAV, "xmlns:card" => Dav::CARDDAV) do
          Dav.element(xml, Dav.prop(namespace, name)) { xml["d"].href(href) if href }
        end
      end.to_xml
      render body: body, status: status, content_type: XML_TYPE
    end

    def addressbook_multiget(book, root)
      requested = Dav.requested_properties(root)
      multistatus = Dav::Multistatus.new

      root.xpath("d:href", "d" => Dav::DAV).each do |href|
        record = record_for_href(href.text)
        if record
          add_properties(multistatus, Carddav::CardResource.new(current_user, record), requested)
        else
          multistatus.add_status(href.text, "HTTP/1.1 404 Not Found")
        end
      end

      render_multistatus multistatus
    end

    # Filters are not applied: every contact matches. Clients filter the vCards they receive.
    def addressbook_query(book, root)
      requested = Dav.requested_properties(root)
      multistatus = Dav::Multistatus.new
      book.children.each { |child| add_properties(multistatus, child, requested) }
      render_multistatus multistatus
    end

    # RFC 6578: with no token, every member; with a token, members changed since it and 404s for removed ones.
    def sync_collection(book, root)
      token = root.at_xpath("d:sync-token", "d" => Dav::DAV)&.text.to_s.strip
      result = book.address_book.changes_since(token) or return render_precondition_error("valid-sync-token", Dav::DAV, :forbidden)
      requested = Dav.requested_properties(root)
      multistatus = Dav::Multistatus.new

      if result[:changes].nil?
        book.children.each { |child| add_properties(multistatus, child, requested) }
      else
        visible = book.address_book.contacts.visible_to_devices.where(resource_name: result[:changes].keys).index_by(&:resource_name)
        visible.merge!(book.address_book.groups.where(resource_name: result[:changes].keys).index_by(&:resource_name))
        result[:changes].each_key do |resource_name|
          if (record = visible[resource_name])
            add_properties(multistatus, Carddav::CardResource.new(current_user, record), requested)
          else
            multistatus.add_status(Carddav::Paths.card(current_user, resource_name), "HTTP/1.1 404 Not Found")
          end
        end
      end

      response.headers["DAV"] = DAV_HEADER
      render body: multistatus.to_xml(sync_token: result[:token]), status: :multi_status, content_type: XML_TYPE
    end

    def add_properties(multistatus, resource, requested)
      case requested
      when :allprop
        multistatus.add(resource.href, found: resource.allprop_properties)
      when :propname
        multistatus.add(resource.href, found: resource.properties.transform_values { nil })
      else
        available = resource.properties
        multistatus.add(resource.href,
          found: requested.select { |property| available.key?(property) }.index_with { |property| available[property] },
          missing: requested.reject { |property| available.key?(property) })
      end
    end

    def render_multistatus(multistatus)
      response.headers["DAV"] = DAV_HEADER
      render body: multistatus.to_xml, status: :multi_status, content_type: XML_TYPE
    end

    def render_report_unsupported
      body = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml["d"].error("xmlns:d" => Dav::DAV) { xml["d"].send(:"supported-report") }
      end.to_xml
      render body: body, status: :forbidden, content_type: XML_TYPE
    end

    # A missing Depth on PROPFIND means infinity; this tree is at most one level deep below a collection.
    def depth
      request.headers["Depth"].to_s.strip == "0" ? 0 : 1
    end

    # Maps a request path to a resource the current user may see, or nil.
    def resolve(path)
      segments = URI::DEFAULT_PARSER.unescape(path).split("/").reject(&:empty?)
      segments.shift if segments.first == "dav"

      case segments
      in [] then Carddav::Root.new(current_user)
      in [ "principals", username ] if own?(username) then Carddav::Principal.new(current_user)
      in [ "addressbooks", username ] if own?(username) then Carddav::Home.new(current_user)
      in [ "addressbooks", username, "contacts" ] if own?(username) then Carddav::AddressBookCollection.new(current_user)
      in [ "addressbooks", username, "contacts", resource_name ] if own?(username)
        record = current_user.address_book.device_resource(resource_name)
        Carddav::CardResource.new(current_user, record) if record
      else nil
      end
    end

    def record_for_href(href)
      path = URI.parse(href).path rescue href
      resource = resolve(path)
      resource.record if resource.is_a?(Carddav::CardResource)
    end

    def own?(username)
      username == current_user.username
    end
end
