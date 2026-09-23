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

  # The vCard served to devices. Members that devices cannot see (archived or trashed contacts) are left out;
  # Rolodex keeps those memberships so unarchiving restores them.
  def served_vcard
    hidden = hidden_member_uids
    return vcard if hidden.empty?

    served = Vcard::Card.parse(vcard)
    served.properties.reject! { |property| member_property?(property) && hidden.include?(member_uid(property)) }
    served.to_s
  end

  def hidden_member_uids
    address_book.contacts.where(uid: card.member_uids).where.not(archived_at: nil)
      .or(address_book.contacts.where(uid: card.member_uids).where.not(trashed_at: nil)).pluck(:uid).to_set
  end

  def etag = %("#{Digest::SHA256.hexdigest(served_vcard)[0, 32]}")

  # Creates a group from the web UI with an Apple-style group vCard.
  def self.create_named(address_book, name)
    if name.to_s.strip.empty?
      return address_book.groups.new.tap { |group| group.errors.add(:name, "can't be blank") }
    end

    uid = SecureRandom.uuid.upcase
    card = Vcard::Card.new([
      Vcard::Property.new("VERSION", "3.0"),
      Vcard::Property.new("PRODID", "-//Rolodex//EN"),
      Vcard::Property.new("N", Vcard.escape(name.to_s.strip)),
      Vcard::Property.new("FN", Vcard.escape(name.to_s.strip)),
      Vcard::Property.new("X-ADDRESSBOOKSERVER-KIND", "group"),
      Vcard::Property.new("UID", uid)
    ])
    address_book.groups.create(uid: uid, resource_name: "#{uid}.vcf", vcard: card.to_s)
  end

  def rename(new_name)
    new_name = new_name.to_s.strip
    if new_name.empty?
      errors.add(:name, "can't be blank")
      return false
    end

    edited = card
    edited.set("N", Vcard.escape(new_name))
    edited.set("FN", Vcard.escape(new_name))
    update(vcard: edited.to_s)
  end

  def add_member(contact_uid)
    return true if card.member_uids.include?(contact_uid)

    edited = card
    index = edited.properties.rindex { |p| p.name == "X-ADDRESSBOOKSERVER-MEMBER" } ||
      edited.properties.index { |p| p.name == "UID" } || edited.properties.size - 1
    edited.properties.insert(index + 1, Vcard::Property.new("X-ADDRESSBOOKSERVER-MEMBER", "urn:uuid:#{contact_uid}"))
    update(vcard: edited.to_s)
  end

  def remove_member(contact_uid)
    return true unless card.member_uids.include?(contact_uid)

    edited = card
    edited.properties.reject! { |property| member_property?(property) && member_uid(property) == contact_uid }
    update(vcard: edited.to_s)
  end

  def self.store_from_device(address_book, resource_name, text, card, existing: nil)
    uid = card.uid.presence || existing&.uid || resource_name.delete_suffix(".vcf")

    if (other = address_book.groups.where(uid: uid).where.not(id: existing&.id).first)
      return { error: :uid_conflict, resource_name: other.resource_name }
    end

    group = existing || address_book.groups.new(resource_name: resource_name)
    group.uid = uid
    group.vcard = existing ? existing.keep_hidden_members(text, card) : text
    group.save ? { record: group } : { error: :invalid, message: group.errors.full_messages.to_sentence }
  end

  # A device never sees hidden members, so its PUT leaves them out. Adds them back to the stored vCard.
  def keep_hidden_members(text, incoming)
    missing = hidden_member_uids.to_a - incoming.member_uids
    return text if missing.empty?

    lines = missing.map { |uid| "X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:#{uid}\r\n" }.join
    text.sub(/END:VCARD\s*\z/i) { "#{lines}#{it}" }
  end

  private
    def member_property?(property) = property.name.in?(%w[ X-ADDRESSBOOKSERVER-MEMBER MEMBER ])

    def member_uid(property) = property.text.strip.sub(/\Aurn:uuid:/i, "")

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
