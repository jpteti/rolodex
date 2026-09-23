module Carddav
  # The server root, where clients look for the current user's principal.
  class Root < Resource
    def href = Paths::ROOT

    def properties
      super.merge(Dav.prop(Dav::DAV, "displayname") => ->(xml) { xml.text "Rolodex" })
    end
  end
end
