module Carddav
  # The addressbook-home-set collection. It holds the user's single address book.
  class Home < Resource
    def href = Paths.home(user)
    def children = [ AddressBookCollection.new(user) ]

    def properties
      super.merge(Dav.prop(Dav::DAV, "displayname") => ->(xml) { xml.text "Address books" })
    end
  end
end
