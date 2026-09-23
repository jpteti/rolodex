# A single-use, expiring URL that registers a passkey. Printed by `bin/rails rolodex:setup_link`.
class SetupLink < ApplicationRecord
  VALID_FOR = 15.minutes

  belongs_to :user

  attr_reader :token

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.issue(user)
    token = SecureRandom.urlsafe_base64(32)
    link = user.setup_links.create!(token_digest: digest(token), expires_at: VALID_FOR.from_now)
    link.instance_variable_set(:@token, token)
    link
  end

  def self.find_usable(token)
    usable.find_by(token_digest: digest(token.to_s))
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  # Marks the link used. Returns false when another request used it first.
  def redeem!
    self.class.usable.where(id: id).update_all(used_at: Time.current) == 1
  end
end
