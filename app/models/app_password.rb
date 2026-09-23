# A per-device password for CardDAV, which Apple Contacts authenticates with HTTP Basic auth.
# Only a SHA-256 digest of the secret is stored. Secrets are 100 random bits, so a fast hash is enough.
class AppPassword < ApplicationRecord
  ALPHABET = "abcdefghijkmnpqrstuvwxyz23456789".chars.freeze # no l, o, 0, 1

  belongs_to :user

  validates :name, presence: true

  attr_reader :secret

  def self.generate(user, name:)
    secret = Array.new(20) { ALPHABET[SecureRandom.random_number(ALPHABET.size)] }.each_slice(5).map(&:join).join("-")
    user.app_passwords.create(name: name, secret_digest: digest(secret)).tap do |app_password|
      app_password.instance_variable_set(:@secret, secret)
    end
  end

  # Returns the user's app password matching the secret, comparing every digest in constant time.
  def self.authenticate(username, secret)
    user = User.find_by(username: username.to_s.strip.downcase) or return
    candidate = digest(secret.to_s)

    user.app_passwords.detect { |app_password| ActiveSupport::SecurityUtils.secure_compare(app_password.secret_digest, candidate) }
  end

  def self.digest(secret)
    OpenSSL::Digest::SHA256.hexdigest(secret.delete("-").downcase)
  end

  def touch_last_used
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 1.minute.ago
  end
end
