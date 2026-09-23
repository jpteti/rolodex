module Carddav
  # A vCard resource in the address book: a contact or a group.
  class CardResource < Resource
    attr_reader :record

    def initialize(user, record)
      super(user)
      @record = record
    end

    def href = Paths.card(user, record.resource_name)
    def collection? = false
    def privileges = super + %w[ write write-content ]

    def properties
      super.merge(
        Dav.prop(Dav::DAV, "getetag") => ->(xml) { xml.text record.etag },
        Dav.prop(Dav::DAV, "getcontenttype") => ->(xml) { xml.text "text/vcard; charset=utf-8" },
        Dav.prop(Dav::DAV, "getcontentlength") => ->(xml) { xml.text record.served_vcard.bytesize.to_s },
        Dav.prop(Dav::DAV, "getlastmodified") => ->(xml) { xml.text record.updated_at.httpdate },
        Dav.prop(Dav::CARDDAV, "address-data") => ->(xml) { xml.text record.served_vcard }
      )
    end

    # address-data is only sent when asked for by name.
    def allprop_properties = properties.except(Dav.prop(Dav::CARDDAV, "address-data"))
  end
end
