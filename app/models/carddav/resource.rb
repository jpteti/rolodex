module Carddav
  # A node in the CardDAV tree. Subclasses define their properties as { Dav::Property => writer }.
  class Resource
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def children = []
    def collection? = true

    def properties
      {
        Dav.prop(Dav::DAV, "resourcetype") => ->(xml) { resource_types(xml) },
        Dav.prop(Dav::DAV, "current-user-principal") => ->(xml) { xml["d"].href Paths.principal(user) },
        Dav.prop(Dav::DAV, "principal-URL") => ->(xml) { xml["d"].href Paths.principal(user) },
        Dav.prop(Dav::DAV, "owner") => ->(xml) { xml["d"].href Paths.principal(user) },
        Dav.prop(Dav::DAV, "current-user-privilege-set") => ->(xml) { privilege_set(xml) },
        Dav.prop(Dav::DAV, "supported-report-set") => ->(xml) { supported_reports(xml) }
      }
    end

    # Properties returned for allprop: everything except expensive or report-only ones.
    def allprop_properties = properties

    def privileges = %w[ read read-current-user-privilege-set ]
    def reports = []

    private
      def resource_types(xml)
        xml["d"].collection if collection?
      end

      def privilege_set(xml)
        privileges.each { |privilege| xml["d"].privilege { xml["d"].send(:"#{privilege}_") } }
      end

      def supported_reports(xml)
        reports.each do |property|
          xml["d"].send(:"supported-report") { xml["d"].report { Dav.element(xml, property) } }
        end
      end
  end
end
