class Passkey < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, :name, presence: true

  def last?
    user.passkeys.count == 1
  end
end
