class User < ApplicationRecord
  has_many :passkeys, dependent: :destroy
  has_many :setup_links, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_one :address_book, dependent: :destroy
  has_many :app_passwords, dependent: :destroy

  validates :username, presence: true, uniqueness: true

  before_validation { self.webauthn_id ||= WebAuthn.generate_user_id }

  after_create { create_address_book! }

  normalizes :username, with: ->(username) { username.strip.downcase }
end
