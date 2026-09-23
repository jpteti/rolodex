# Writes a vCard 3.0 for a contact from form fields. Apple clients prefer vCard 3.0.
class ContactCard
  def initialize(uid:, given_name: nil, family_name: nil, organization: nil, emails: [], phones: [])
    @uid = uid
    @given_name = given_name.to_s.strip
    @family_name = family_name.to_s.strip
    @organization = organization.to_s.strip
    @emails = Array(emails).map(&:strip).compact_blank
    @phones = Array(phones).map(&:strip).compact_blank
  end

  def to_s
    card.to_s
  end

  def card
    Vcard::Card.new.tap do |card|
      card.properties << property("VERSION", "3.0")
      card.properties << property("PRODID", "-//Rolodex//EN")
      card.properties << property("UID", @uid)
      card.properties << property("N", [ @family_name, @given_name, "", "", "" ].map { |part| Vcard.escape(part) }.join(";"))
      card.properties << property("FN", Vcard.escape(full_name))
      card.properties << property("ORG", Vcard.escape(@organization)) if @organization.present?
      card.properties << property("X-ABSHOWAS", "COMPANY") if company?
      @emails.each { |email| card.properties << property("EMAIL", Vcard.escape(email), params: [ [ "TYPE", "INTERNET" ] ]) }
      @phones.each { |phone| card.properties << property("TEL", Vcard.escape(phone), params: [ [ "TYPE", "VOICE" ] ]) }
    end
  end

  private
    def full_name
      [ @given_name, @family_name ].compact_blank.join(" ").presence || @organization
    end

    def company?
      @given_name.blank? && @family_name.blank? && @organization.present?
    end

    def property(name, value, params: [])
      Vcard::Property.new(name, value, params: params)
    end
end
