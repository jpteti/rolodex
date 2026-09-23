module Carddav
  class AddressBookCollection < Resource
    def href = Paths.address_book(user)

    def address_book = user.address_book

    def contacts = address_book.contacts.visible_to_devices

    def children = contacts.map { |contact| ContactResource.new(user, contact) }

    def reports = [ Dav.prop(Dav::CARDDAV, "addressbook-multiget"), Dav.prop(Dav::CARDDAV, "addressbook-query") ]

    def properties
      super.merge(
        Dav.prop(Dav::DAV, "displayname") => ->(xml) { xml.text address_book.name },
        Dav.prop(Dav::CALENDARSERVER, "getctag") => ->(xml) { xml.text ctag },
        Dav.prop(Dav::CARDDAV, "addressbook-description") => ->(xml) { xml.text "Rolodex contacts" },
        Dav.prop(Dav::CARDDAV, "supported-address-data") => ->(xml) {
          xml["card"].send(:"address-data-type", "content-type" => "text/vcard", "version" => "3.0")
        },
        Dav.prop(Dav::CARDDAV, "max-resource-size") => ->(xml) { xml.text Contact::MAX_VCARD_BYTES.to_s }
      )
    end

    def ctag = %("#{address_book.ctag}")

    private
      def resource_types(xml)
        super
        xml["card"].addressbook
      end
  end
end
