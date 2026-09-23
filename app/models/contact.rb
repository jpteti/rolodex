# A contact is its raw vCard (the source of truth) plus columns extracted from it for listing and search.
class Contact < ApplicationRecord
  MAX_VCARD_BYTES = 5.megabytes

  belongs_to :address_book

  serialize :emails, type: Array, coder: JSON
  serialize :phones, type: Array, coder: JSON

  validates :uid, presence: true, uniqueness: { scope: :address_book_id }
  validates :resource_name, presence: true, uniqueness: { scope: :address_book_id }
  validates :vcard, :display_name, presence: true

  before_validation :extract_fields, if: :vcard_changed?
  after_create :log_sync_change_on_create
  after_update :log_sync_change_on_update
  after_destroy :log_sync_change_on_destroy
  after_commit :record_address_book_change

  scope :sorted, -> { order(:sort_key, :id) }
  scope :trashed, -> { where.not(trashed_at: nil) }
  scope :untrashed, -> { where(trashed_at: nil) }
  scope :active, -> { untrashed.where(archived_at: nil) }
  scope :archived, -> { untrashed.where.not(archived_at: nil) }
  # Contacts that CardDAV clients see. Archived and trashed contacts are hidden so devices remove them.
  scope :visible_to_devices, -> { active }

  # Matches name, nickname, organization, or email ignoring case, and phone numbers ignoring formatting.
  scope :search, ->(query) {
    text = query.to_s.strip.downcase
    next all if text.empty?

    digits = text.gsub(/\D/, "")
    condition = arel_table[:search_text].matches("%#{sanitize_sql_like(text)}%")
    condition = condition.or(arel_table[:phone_digits].matches("%#{digits}%")) if digits.length >= 3
    where(condition)
  }

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

  # Builds the vCard for a new contact from simple form fields.
  def self.build_from_fields(address_book, fields)
    uid = SecureRandom.uuid.upcase
    address_book.contacts.new(uid: uid, resource_name: "#{uid}.vcf", vcard: ContactCard.new(**fields.to_h.symbolize_keys, uid: uid).to_s)
  end

  def photo = ContactPhoto.read(card)

  def initials
    source = [ given_name, family_name ].compact_blank.presence || [ display_name ]
    source.map { |part| part.to_s[/\p{Alnum}/] }.compact.join.first(2).upcase
  end

  def archived? = archived_at.present?

  def visible_to_devices? = archived_at.nil? && trashed_at.nil?

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def trashed? = trashed_at.present?

  def trash!
    update!(trashed_at: Time.current)
  end

  # Returns the contact to where it was before it was trashed: the main list, or the Archive.
  def restore!
    update!(trashed_at: nil)
  end

  # Stores a vCard sent by a CardDAV client, keeping the text exactly as sent.
  # Returns { contact: } or { error:, ... }.
  def self.store_from_device(address_book, resource_name, body, existing: nil)
    text = body.dup.force_encoding(Encoding::UTF_8)
    return { error: :invalid, message: "vCard is not valid UTF-8" } unless text.valid_encoding?

    card = Vcard::Card.parse(text)
    uid = card.uid.presence || existing&.uid || resource_name.delete_suffix(".vcf")

    if (other = address_book.contacts.where(uid: uid).where.not(id: existing&.id).first)
      return { error: :uid_conflict, resource_name: other.resource_name }
    end
    if existing.nil? && address_book.contacts.exists?(resource_name: resource_name)
      return { error: :hidden_resource }
    end

    contact = existing || address_book.contacts.new(resource_name: resource_name)
    contact.uid = uid
    contact.vcard = text
    contact.save ? { contact: contact } : { error: :invalid, message: contact.errors.full_messages.to_sentence }
  rescue Vcard::ParseError => error
    { error: :invalid, message: error.message }
  end

  private
    def extract_fields
      card = self.card
      self.uid = card.uid if card.uid.present?
      family, given = card["N"]&.components
      self.given_name = given.presence
      self.family_name = family.presence
      self.organization = card["ORG"]&.components&.first.presence
      self.emails = card.all("EMAIL").map(&:text).compact_blank
      self.phones = card.all("TEL").map(&:text).compact_blank
      self.display_name = card.value("FN").presence || [ given_name, family_name ].compact.join(" ").presence ||
        organization || emails.first || phones.first || "No Name"
      self.has_photo = card["PHOTO"].present?
      self.search_text = [ display_name, given_name, family_name, card.value("NICKNAME"), organization, *emails ].compact_blank.join(" ").downcase
      self.phone_digits = phones.map { |phone| phone.gsub(/\D/, "") }.join(" ")
      self.sort_key = ([ family_name, given_name ].compact.join(" ").presence || organization || display_name).downcase
      self.etag = %("#{Digest::SHA256.hexdigest(vcard)[0, 32]}")
    rescue Vcard::ParseError => error
      errors.add(:vcard, error.message)
    end

    def log_sync_change(removed:, resource_name: self.resource_name)
      address_book.sync_changes.create!(resource_name: resource_name, removed: removed)
    end

    def log_sync_change_on_create
      log_sync_change(removed: false) if visible_to_devices?
    end

    def log_sync_change_on_update
      was_visible = archived_at_before_last_save.nil? && trashed_at_before_last_save.nil?

      if saved_change_to_resource_name? && was_visible
        log_sync_change(removed: true, resource_name: resource_name_before_last_save)
      end

      if was_visible && !visible_to_devices?
        log_sync_change(removed: true)
      elsif visible_to_devices? && (!was_visible || saved_change_to_vcard? || saved_change_to_resource_name?)
        log_sync_change(removed: false)
      end
    end

    def log_sync_change_on_destroy
      log_sync_change(removed: true) if visible_to_devices?
    end

    def record_address_book_change
      address_book.record_change! unless destroyed? && address_book.destroyed?
    end
end
