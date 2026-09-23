class AddressBook < ApplicationRecord
  belongs_to :user
  has_many :contacts, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :sync_changes, dependent: :delete_all
  has_many :imports, dependent: :delete_all

  # Changes whenever a contact visible to devices changes. Served as the CalendarServer getctag.
  def record_change!
    increment!(:ctag)
  end

  # A resource devices can see: a visible contact or a group.
  def device_resource(resource_name)
    contacts.visible_to_devices.find_by(resource_name: resource_name) || groups.find_by(resource_name: resource_name)
  end

  def device_resources
    contacts.visible_to_devices.to_a + groups.to_a
  end

  # Stores a vCard PUT by a device as a contact or, for Apple group cards, a group.
  # Returns { record: } or { error:, ... }.
  def store_from_device(resource_name, body, existing: nil)
    text = body.dup.force_encoding(Encoding::UTF_8)
    return { error: :invalid, message: "vCard is not valid UTF-8" } unless text.valid_encoding?

    card = Vcard::Card.parse(text)
    model = card.group? ? Group : Contact
    return { error: :invalid, message: "A contact cannot become a group or the reverse" } if existing && !existing.is_a?(model)
    if existing.nil? && (contacts.exists?(resource_name: resource_name) || groups.exists?(resource_name: resource_name))
      return { error: :hidden_resource }
    end

    model.store_from_device(self, resource_name, text, card, existing: existing)
  rescue Vcard::ParseError => error
    { error: :invalid, message: error.message }
  end

  def sync_token
    SyncChange.token_for(sync_changes.maximum(:id) || 0)
  end

  # Resource names changed since the token, mapped to whether each was removed, plus the token to hand back.
  # Returns nil for a token that is not ours or is ahead of the log. A blank token means a full sync.
  def changes_since(token)
    latest = sync_changes.maximum(:id) || 0
    since = token.blank? ? nil : SyncChange.parse_token(token)
    return if token.present? && (since.nil? || since > latest)

    changes = since && sync_changes.where(id: (since + 1)..latest).order(:id).each_with_object({}) do |change, names|
      names[change.resource_name] = change.removed
    end
    { changes: changes, token: SyncChange.token_for(latest) }
  end
end
