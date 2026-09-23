module Carddav
  # URL layout of the CardDAV tree. Every user has one address book named "contacts".
  module Paths
    ROOT = "/dav/".freeze

    module_function

    def principal(user) = "/dav/principals/#{escape(user.username)}/"
    def home(user) = "/dav/addressbooks/#{escape(user.username)}/"
    def address_book(user) = "#{home(user)}contacts/"
    def card(user, resource_name) = "#{address_book(user)}#{escape(resource_name)}"

    def escape(segment) = ERB::Util.url_encode(segment)
  end
end
