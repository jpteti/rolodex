module Carddav
  class Principal < Resource
    def href = Paths.principal(user)

    def properties
      super.merge(
        Dav.prop(Dav::DAV, "displayname") => ->(xml) { xml.text user.username },
        Dav.prop(Dav::CARDDAV, "addressbook-home-set") => ->(xml) { xml["d"].href Paths.home(user) },
        Dav.prop(Dav::DAV, "principal-collection-set") => ->(xml) { xml["d"].href "/dav/principals/" }
      )
    end

    private
      def resource_types(xml)
        super
        xml["d"].principal
      end
  end
end
