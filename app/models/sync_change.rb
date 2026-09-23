# One row per change a device must learn about: a resource that appeared or changed, or one that went away.
# The row id is the sync token (RFC 6578). Archive and trash count as removals; unarchive and restore as additions.
class SyncChange < ApplicationRecord
  TOKEN_PREFIX = "http://rolodex.app/ns/sync/".freeze

  belongs_to :address_book

  def self.token_for(id) = "#{TOKEN_PREFIX}#{id}"

  # Returns the change id in a token, or nil if the token is not one of ours.
  def self.parse_token(token)
    Integer(token.to_s.delete_prefix(TOKEN_PREFIX), 10) if token.to_s.start_with?(TOKEN_PREFIX)
  rescue ArgumentError
    nil
  end
end
