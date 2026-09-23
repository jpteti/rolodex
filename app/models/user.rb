class User < ApplicationRecord
  has_many :passkeys, dependent: :destroy
  has_many :setup_links, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :username, presence: true, uniqueness: true

  before_validation { self.webauthn_id ||= WebAuthn.generate_user_id }

  normalizes :username, with: ->(username) { username.strip.downcase }
end
