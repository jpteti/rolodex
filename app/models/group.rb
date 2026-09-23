# An Apple Contacts group: a vCard with X-ADDRESSBOOKSERVER-KIND:group listing members by UID.
# Stored apart from contacts so group cards never show up as people.
class Group < ApplicationRecord
  belongs_to :address_book
  has_many :memberships, class_name: "GroupMembership", dependent: :delete_all

  validates :uid, presence: true, uniqueness: { scope: :address_book_id }
  validates :resource_name, presence: true, uniqueness: { scope: :address_book_id }
  validates :vcard, :name, presence: true

  before_validation :extract_fields, if: :vcard_changed?
  after_save :sync_memberships, if: :saved_change_to_vcard?
  after_create { log_sync_change(removed: false) }
  after_update { log_sync_change(removed: false) if saved_change_to_vcard? }
  after_destroy { log_sync_change(removed: true) }
  after_commit { address_book.record_change! unless address_book.destroyed? }

  scope :sorted, -> { order(Arel.sql("lower(name)"), :id) }

  def card
    @card ||= Vcard::Card.parse(vcard)
  end

  def vcard=(text)
    @card = nil
    super
  end

  def reload(...)
    @card = nil
    super
  end

  def member_uids = memberships.pluck(:contact_uid)

  def contacts
    address_book.contacts.where(uid: member_uids)
  end

  # The vCard served to devices.
  def served_vcard = vcard

  def etag = %("#{Digest::SHA256.hexdigest(served_vcard)[0, 32]}")

  def self.store_from_device(address_book, resource_name, text, card, existing: nil)
    uid = card.uid.presence || existing&.uid || resource_name.delete_suffix(".vcf")

    if (other = address_book.groups.where(uid: uid).where.not(id: existing&.id).first)
      return { error: :uid_conflict, resource_name: other.resource_name }
    end

    group = existing || address_book.groups.new(resource_name: resource_name)
    group.uid = uid
    group.vcard = text
    group.save ? { record: group } : { error: :invalid, message: group.errors.full_messages.to_sentence }
  end

  private
    def extract_fields
      self.uid = card.uid if card.uid.present?
      self.name = card.value("FN").presence || card["N"]&.components&.first.presence || "Untitled group"
    rescue Vcard::ParseError => error
      errors.add(:vcard, error.message)
    end

    def sync_memberships
      uids = card.member_uids
      memberships.where.not(contact_uid: uids).delete_all
      (uids - memberships.pluck(:contact_uid)).each { |uid| memberships.create!(contact_uid: uid) }
    end

    def log_sync_change(removed:)
      address_book.sync_changes.create!(resource_name: resource_name, removed: removed)
    end
end
