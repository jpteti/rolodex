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

      unless resource.is_a?(Carddav::AddressBookCollection) && root.namespace&.href == Dav::CARDDAV
        return render_report_unsupported
      end

      case root.name
      when "addressbook-multiget" then addressbook_multiget(resource, root)
      when "addressbook-query" then addressbook_query(resource, root)
      else render_report_unsupported
      end
    end

    def show
      resource = resolve(request.path) or return head(:not_found)
      return render(plain: "Rolodex CardDAV\n") if resource.collection?

      contact = resource.contact
      response.headers["ETag"] = contact.etag
      response.headers["Last-Modified"] = contact.updated_at.httpdate
      return head(:not_modified) if request.headers["If-None-Match"] == contact.etag

      send_data contact.vcard, type: "text/vcard; charset=utf-8", disposition: :inline
    end

    def method_not_allowed
      response.headers["Allow"] = allowed_methods.join(", ")
      head :method_not_allowed
    end

    def allowed_methods
      %w[ OPTIONS GET HEAD PROPFIND PROPPATCH REPORT ]
    end

    def addressbook_multiget(book, root)
      requested = Dav.requested_properties(root)
      multistatus = Dav::Multistatus.new

      root.xpath("d:href", "d" => Dav::DAV).each do |href|
        contact = contact_for_href(book, href.text)
        if contact
          add_properties(multistatus, Carddav::ContactResource.new(current_user, contact), requested)
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
        contact = current_user.address_book.contacts.visible_to_devices.find_by(resource_name: resource_name)
        Carddav::ContactResource.new(current_user, contact) if contact
      else nil
      end
    end

    def contact_for_href(book, href)
      path = URI.parse(href).path rescue href
      resource = resolve(path)
      resource.contact if resource.is_a?(Carddav::ContactResource)
    end

    def own?(username)
      username == current_user.username
    end
end
