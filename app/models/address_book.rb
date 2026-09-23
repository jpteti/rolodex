class AddressBook < ApplicationRecord
  belongs_to :user
  has_many :contacts, dependent: :destroy
  has_many :sync_changes, dependent: :delete_all
  has_many :imports, dependent: :delete_all

  # Changes whenever a contact visible to devices changes. Served as the CalendarServer getctag.
  def record_change!
    increment!(:ctag)
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
