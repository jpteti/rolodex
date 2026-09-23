module Carddav
  class ContactResource < Resource
    attr_reader :contact

    def initialize(user, contact)
      super(user)
      @contact = contact
    end

    def href = Paths.contact(user, contact.resource_name)
    def collection? = false
    def privileges = super + %w[ write write-content ]

    def properties
      super.merge(
        Dav.prop(Dav::DAV, "getetag") => ->(xml) { xml.text contact.etag },
        Dav.prop(Dav::DAV, "getcontenttype") => ->(xml) { xml.text "text/vcard; charset=utf-8" },
        Dav.prop(Dav::DAV, "getcontentlength") => ->(xml) { xml.text contact.vcard.bytesize.to_s },
        Dav.prop(Dav::DAV, "getlastmodified") => ->(xml) { xml.text contact.updated_at.httpdate },
        Dav.prop(Dav::CARDDAV, "address-data") => ->(xml) { xml.text contact.vcard }
      )
    end

    # address-data is only sent when asked for by name.
    def allprop_properties = properties.except(Dav.prop(Dav::CARDDAV, "address-data"))
  end
end
