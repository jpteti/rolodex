# The web form for a contact. Loads fields from the vCard and writes changes back into it, touching only
# properties whose values changed. Every property the form does not show is kept as it was.
class ContactEditor
  include ActiveModel::Model

  NAME_PARTS = %i[ family_name given_name middle_name prefix suffix ].freeze # N component order
  TEXT_FIELDS = { nickname: "NICKNAME", job_title: "TITLE", note: "NOTE" }.freeze
  SINGLE_FIELDS = NAME_PARTS + TEXT_FIELDS.keys + %i[ organization birthday ]
  ADDRESS_PARTS = %i[ street city region postal_code country ].freeze # ADR components 2..6

  # A repeated field. ref is the index of the property it came from, or blank for a new row.
  Row = Struct.new(:ref, :label, :value, *ADDRESS_PARTS, keyword_init: true) do
    def blank? = ([ value ] + ADDRESS_PARTS.map { |part| self[part] }).all?(&:blank?)
  end

  REPEATED = { emails: "EMAIL", phones: "TEL", addresses: "ADR", urls: "URL" }.freeze

  attr_accessor(*SINGLE_FIELDS, *REPEATED.keys)
  attr_reader :card

  validate :something_to_show
  validate :birthday_format

  def self.for(contact)
    new(Vcard::Card.parse(contact.vcard))
  end

  def self.blank(uid:)
    card = Vcard::Card.new([
      Vcard::Property.new("VERSION", "3.0"),
      Vcard::Property.new("PRODID", "-//Rolodex//EN"),
      Vcard::Property.new("UID", uid),
      Vcard::Property.new("N", ";;;;")
    ])
    new(card)
  end

  def initialize(card)
    @card = card
    load_fields
  end

  def assign(params)
    SINGLE_FIELDS.each { |field| public_send("#{field}=", params[field].to_s.strip) if params.key?(field) }
    REPEATED.each_key do |field|
      rows = params.fetch(field, {})
      rows = rows.values if rows.respond_to?(:values)
      public_send("#{field}=", rows.map { |row| Row.new(**row.to_h.symbolize_keys.slice(*Row.members)) })
    end
    self
  end

  # Returns the updated vCard text, or the original text when nothing changed.
  def to_vcard(original_text = nil)
    before = self.class.new(Vcard::Card.parse(card.to_s))
    write_names(before)
    write_text_fields(before)
    write_organization(before)
    write_birthday(before)
    REPEATED.each { |field, name| write_rows(before, field, name) }

    changed = card.to_s
    original_text && changed == Vcard::Card.parse(original_text).to_s ? original_text : changed
  end

  def label_suggestions(field) = Vcard::Label.suggestions(REPEATED.fetch(field))

  def display_name
    [ prefix, given_name, middle_name, family_name, suffix ].compact_blank.join(" ").presence || organization.presence
  end

  private
    def load_fields
      n = card["N"]&.components || []
      NAME_PARTS.each_with_index { |part, index| public_send("#{part}=", n[index].to_s) }
      TEXT_FIELDS.each { |field, name| public_send("#{field}=", card.value(name).to_s) }
      self.organization = card["ORG"]&.components&.first.to_s
      self.birthday = read_birthday
      REPEATED.each do |field, name|
        rows = card.all(name).each_with_index.map { |property, index| row_for(property, index) }
        public_send("#{field}=", rows)
      end
    end

    def row_for(property, index)
      label = Vcard::Label.read(card, property)
      if property.name == "ADR"
        parts = property.components
        Row.new(ref: index.to_s, label: label, **ADDRESS_PARTS.each_with_index.to_h { |part, i| [ part, parts[i + 2].to_s ] })
      else
        Row.new(ref: index.to_s, label: label, value: property.text)
      end
    end

    def write_names(before)
      names_changed = NAME_PARTS.any? { |part| public_send(part).to_s != before.public_send(part).to_s }
      company_changed = organization.to_s != before.organization.to_s && NAME_PARTS.all? { |part| public_send(part).blank? }
      return unless names_changed || company_changed

      if names_changed
        n = card["N"]
        components = n ? n.components : []
        components.fill("", components.size...5)
        NAME_PARTS.each_with_index { |part, index| components[index] = public_send(part).to_s }
        value = components.map { |component| Vcard.escape(component) }.join(";")
        n ? n.value = value : insert_after_header(Vcard::Property.new("N", value))
      end

      fn = card["FN"]
      value = Vcard.escape(display_name.to_s)
      fn ? fn.value = value : insert_after_header(Vcard::Property.new("FN", value))

      if NAME_PARTS.all? { |part| public_send(part).blank? } && organization.present? && card["X-ABSHOWAS"].nil?
        insert_after_header(Vcard::Property.new("X-ABSHOWAS", "COMPANY"))
      end
    end

    def write_text_fields(before)
      TEXT_FIELDS.each do |field, name|
        next if public_send(field).to_s == before.public_send(field).to_s

        set_single(name, Vcard.escape(public_send(field).to_s.gsub("\r\n", "\n")))
      end
    end

    def write_organization(before)
      return if organization.to_s == before.organization.to_s

      org = card["ORG"]
      rest = org ? Vcard.split_raw(org.value, ";").drop(1) : []
      if organization.blank? && rest.all?(&:blank?)
        card.delete("ORG")
      else
        set_single("ORG", ([ Vcard.escape(organization.to_s) ] + rest).join(";"))
      end
    end

    def write_birthday(before)
      return if birthday.to_s == before.birthday.to_s

      case birthday.to_s
      when ""
        card.delete("BDAY")
      when /\A\d{4}-\d{2}-\d{2}\z/
        set_single("BDAY", birthday, params: [ [ "VALUE", "date" ] ])
      when /\A(\d{2})-(\d{2})\z/
        set_single("BDAY", "1604-#{$1}-#{$2}", params: [ [ "X-APPLE-OMIT-YEAR", "1604" ], [ "VALUE", "date" ] ])
      end
    end

    # Birthdays show as YYYY-MM-DD, or MM-DD when the year is unknown.
    def read_birthday
      property = card["BDAY"] or return ""
      value = property.text
      omit_year = property.param("X-APPLE-OMIT-YEAR")

      case value
      when /\A--(\d{2})-?(\d{2})\z/ then "#{$1}-#{$2}"
      when /\A(\d{4})-?(\d{2})-?(\d{2})/
        omit_year && omit_year == $1 ? "#{$2}-#{$3}" : "#{$1}-#{$2}-#{$3}"
      else value
      end
    end

    def write_rows(before, field, name)
      originals = card.all(name)
      rows = public_send(field).reject(&:blank?)
      old_rows = before.public_send(field)

      kept = rows.map do |row|
        original = row.ref.present? ? originals[row.ref.to_i] : nil
        old_row = row.ref.present? ? old_rows[row.ref.to_i] : nil
        property = original || Vcard::Property.new(name, "", params: default_params(name))

        property.value = encode_row(name, row) if old_row.nil? || row_value(row) != row_value(old_row)
        [ property, row.label.to_s, old_row&.label.to_s, original.nil? ]
      end

      removed = originals - kept.map(&:first)
      card.replace_all(name, kept.map(&:first))
      kept.each do |property, label, old_label, added|
        Vcard::Label.write(card, property, label) if added ? label.present? : !label.casecmp?(old_label)
      end
      remove_orphaned_groups(removed)
    end

    def row_value(row)
      [ row.value.to_s ] + ADDRESS_PARTS.map { |part| row[part].to_s }
    end

    def encode_row(name, row)
      case name
      when "ADR"
        original = row.ref.present? ? card.all("ADR")[row.ref.to_i]&.components : nil
        pobox, extended = original ? original.first(2) : [ "", "" ]
        [ pobox.to_s, extended.to_s, *ADDRESS_PARTS.map { |part| row[part].to_s.gsub("\r\n", "\n") } ].map { |part| Vcard.escape(part) }.join(";")
      when "URL" then row.value.to_s.strip
      else Vcard.escape(row.value.to_s.strip)
      end
    end

    def default_params(name)
      case name
      when "EMAIL" then [ [ "TYPE", "INTERNET" ] ]
      when "TEL" then [ [ "TYPE", "VOICE" ] ]
      else []
      end
    end

    # Removes Apple's helper properties (X-ABLabel, X-ABADR) left in the item group of a removed property.
    def remove_orphaned_groups(removed)
      removed.filter_map(&:group).uniq.each do |group|
        in_group = card.properties.select { |property| property.group&.casecmp?(group) }
        next if in_group.any? { |property| !property.name.start_with?("X-AB") }

        card.properties.reject! { |property| in_group.include?(property) }
      end
    end

    def set_single(name, value, params: nil)
      if value.blank?
        card.delete(name)
      elsif (property = card[name])
        property.value = value
        property.params = params if params
        card.properties.reject! { |other| other.name == name && !other.equal?(property) }
      else
        insert_after_header(Vcard::Property.new(name, value, params: params || []))
      end
    end

    # New properties go before END, after the existing ones.
    def insert_after_header(property)
      card.properties << property
    end

    def something_to_show
      values = [ display_name ] + REPEATED.keys.flat_map { |field| public_send(field).reject(&:blank?) }
      errors.add(:base, "Enter a name, organization, email, phone, address, or URL") if values.compact_blank.empty?
    end

    def birthday_format
      return if birthday.blank? || birthday.match?(/\A(\d{4}-)?\d{2}-\d{2}\z/)

      errors.add(:birthday, "must look like 1990-05-10, or 05-10 without a year")
    end
end
