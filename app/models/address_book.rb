class AddressBook < ApplicationRecord
  belongs_to :user
  has_many :contacts, dependent: :destroy

  # Changes whenever a contact visible to devices changes. Served as the CalendarServer getctag.
  def record_change!
    increment!(:ctag)
  end
end
