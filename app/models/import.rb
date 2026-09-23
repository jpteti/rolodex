# A .vcf upload, processed in the background by ImportJob.
class Import < ApplicationRecord
  STATUSES = %w[ pending running done failed ].freeze

  belongs_to :address_book

  attribute :failures, :json, default: -> { [] }

  validates :status, inclusion: { in: STATUSES }

  def finished? = status.in?(%w[ done failed ])

  # Creates or updates one contact per vCard in the source. A vCard whose UID matches an existing
  # contact updates it; a vCard without a UID gets a generated one.
  def run
    update!(status: "running")
    Vcard.split(source).each_with_index { |text, index| import_card(text, index + 1) }
    update!(status: "done", finished_at: Time.current, source: "")
  rescue => error
    update!(status: "failed", finished_at: Time.current, failures: failures + [ { "card" => nil, "name" => nil, "reason" => error.message } ])
    raise
  end

  private
    def import_card(text, number)
      text = text.dup.force_encoding(Encoding::UTF_8)
      raise Vcard::ParseError, "not valid UTF-8" unless text.valid_encoding?

      card = Vcard::Card.parse(text)
      name = card.value("FN").presence || card["N"]&.components&.values_at(1, 0)&.compact_blank&.join(" ")

      if card.uid.blank?
        card.properties << Vcard::Property.new("UID", SecureRandom.uuid.upcase)
        text = card.to_s
      end

      records = card.group? ? address_book.groups : address_book.contacts
      if (record = records.find_by(uid: card.uid))
        record.update!(vcard: text)
        increment!(:updated_count)
      else
        records.create!(uid: card.uid, resource_name: resource_name_for(card.uid), vcard: text)
        increment!(:created_count)
      end
    rescue Vcard::ParseError, ActiveRecord::RecordInvalid => error
      self.failures = failures + [ { "card" => number, "name" => name, "reason" => error.message } ]
      save!
    end

    def resource_name_for(uid)
      name = uid.match?(/\A[\w.-]{1,200}\z/) ? "#{uid}.vcf" : "#{SecureRandom.uuid.upcase}.vcf"
      taken = address_book.contacts.exists?(resource_name: name) || address_book.groups.exists?(resource_name: name)
      taken ? "#{SecureRandom.uuid.upcase}.vcf" : name
    end
end
