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
  after_commit :record_address_book_change

  scope :sorted, -> { order(:sort_key, :id) }
  scope :trashed, -> { where.not(trashed_at: nil) }
  scope :untrashed, -> { where(trashed_at: nil) }
  scope :active, -> { untrashed.where(archived_at: nil) }
  scope :archived, -> { untrashed.where.not(archived_at: nil) }
  # Contacts that CardDAV clients see. Archived and trashed contacts are hidden so devices remove them.
  scope :visible_to_devices, -> { active }

  def card
    @card ||= Vcard::Card.parse(vcard)
  end

  def vcard=(text)
    @card = nil
    super
  end

  # Builds the vCard for a new contact from simple form fields.
  def self.build_from_fields(address_book, fields)
    uid = SecureRandom.uuid.upcase
    address_book.contacts.new(uid: uid, resource_name: "#{uid}.vcf", vcard: ContactCard.new(**fields.to_h.symbolize_keys, uid: uid).to_s)
  end

  def archived? = archived_at.present?

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
      self.sort_key = ([ family_name, given_name ].compact.join(" ").presence || organization || display_name).downcase
      self.etag = %("#{Digest::SHA256.hexdigest(vcard)[0, 32]}")
    rescue Vcard::ParseError => error
      errors.add(:vcard, error.message)
    end

    def record_address_book_change
      address_book.record_change! unless destroyed? && address_book.destroyed?
    end
end
