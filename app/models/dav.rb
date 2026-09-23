# WebDAV (RFC 4918) and CardDAV (RFC 6352) building blocks: namespaces, request parsing, and
# multistatus responses.
module Dav
  NS = {
    "d" => "DAV:",
    "card" => "urn:ietf:params:xml:ns:carddav",
    "cs" => "http://calendarserver.org/ns/"
  }.freeze

  DAV = NS["d"]
  CARDDAV = NS["card"]
  CALENDARSERVER = NS["cs"]

  # A property name: namespace URI plus local name.
  Property = Data.define(:namespace, :name) do
    def to_s = "{#{namespace}}#{name}"
  end

  def self.prop(namespace, name) = Property.new(namespace, name)

  class BadRequest < StandardError; end

  # Parses an XML request body. Returns nil for an empty body.
  def self.parse_xml(body)
    return if body.blank?

    Nokogiri::XML(body) { |config| config.strict.nonet }
  rescue Nokogiri::XML::SyntaxError => error
    raise BadRequest, "Invalid XML: #{error.message}"
  end

  # Reads the properties requested by a PROPFIND or REPORT body. Returns :allprop, :propname, or an array.
  def self.requested_properties(root)
    return :allprop if root.nil?

    return :allprop if root.at_xpath("d:allprop", "d" => DAV)
    return :propname if root.at_xpath("d:propname", "d" => DAV)

    prop = root.at_xpath("d:prop", "d" => DAV) or return :allprop
    prop.element_children.map { |element| Property.new(element.namespace&.href, element.name) }
  end

  # Builds a 207 Multi-Status body.
  class Multistatus
    def initialize
      @responses = []
    end

    # found: { Property => ->(xml) { ... } }, missing: [Property], status_for_missing: HTTP status line
    def add(href, found: {}, missing: [], missing_status: "HTTP/1.1 404 Not Found")
      @responses << [ :props, href, found, missing, missing_status ]
    end

    def add_status(href, status)
      @responses << [ :status, href, status ]
    end

    def add_raw(&block)
      @responses << [ :raw, block ]
    end

    def to_xml(sync_token: nil)
      Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml["d"].multistatus(NS.transform_keys { |prefix| "xmlns:#{prefix}" }) do
          @responses.each { |response| build_response(xml, *response) }
          xml["d"].send(:"sync-token", sync_token) if sync_token
        end
      end.to_xml
    end

    private
      def build_response(xml, kind, *args)
        case kind
        when :status
          href, status = args
          xml["d"].response do
            xml["d"].href href
            xml["d"].status status
          end
        when :raw
          args.first.call(xml)
        when :props
          href, found, missing, missing_status = args
          xml["d"].response do
            xml["d"].href href
            if found.any?
              xml["d"].propstat do
                xml["d"].prop { found.each { |property, writer| Dav.element(xml, property) { writer&.call(xml) } } }
                xml["d"].status "HTTP/1.1 200 OK"
              end
            end
            if missing.any?
              xml["d"].propstat do
                xml["d"].prop { missing.each { |property| Dav.element(xml, property) } }
                xml["d"].status missing_status
              end
            end
          end
        end
      end
  end

  # Writes an element for a property, using a known prefix or declaring its namespace inline.
  def self.element(xml, property, &block)
    prefix = NS.key(property.namespace)
    if prefix
      xml[prefix].send(:"#{property.name}_", &block)
    else
      attributes = property.namespace ? { "xmlns" => property.namespace } : {}
      xml.send(:"#{property.name}_", attributes, &block)
    end
  end
end
