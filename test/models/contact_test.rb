require "test_helper"

class ContactTest < ActiveSupport::TestCase
  setup { @book = address_books(:owner) }

  def create_contact(**fields)
    Contact.build_from_fields(@book, fields).tap(&:save!)
  end

  test "generates a vCard 3.0 with a UID and extracts matching columns" do
    contact = create_contact(given_name: "Ada", family_name: "Lovelace", organization: "Analytical Engines",
      emails: [ "ada@example.com", "ada@work.example" ], phones: [ "+44 20 1234 5678" ])
    card = Vcard::Card.parse(contact.vcard)

    assert_equal "3.0", card.version
    assert_match(/\A[0-9A-F-]{36}\z/, card.uid)
    assert_equal card.uid, contact.uid
    assert_equal "#{contact.uid}.vcf", contact.resource_name
    assert_equal [ "Lovelace", "Ada", "", "", "" ], card["N"].components
    assert_equal "Ada Lovelace", card.value("FN")
    assert_equal "Analytical Engines", card.value("ORG")
    assert_equal [ "ada@example.com", "ada@work.example" ], card.all("EMAIL").map(&:text)
    assert_equal [ "+44 20 1234 5678" ], card.all("TEL").map(&:text)

    assert_equal "Ada", contact.given_name
    assert_equal "Lovelace", contact.family_name
    assert_equal "Ada Lovelace", contact.display_name
    assert_equal "Analytical Engines", contact.organization
    assert_equal [ "ada@example.com", "ada@work.example" ], contact.reload.emails
    assert_equal [ "+44 20 1234 5678" ], contact.phones
  end

  test "extracts columns from a vCard written elsewhere" do
    contact = @book.contacts.create!(uid: "x", resource_name: "x.vcf", vcard: VcardTest::APPLE_CARD)

    assert_equal "1234-ABCD", contact.uid
    assert_equal "Johnny Appleseed", contact.display_name
    assert_equal "Apple Inc.", contact.organization
    assert_equal [ "johnny@example.com" ], contact.emails
    assert_equal [ "(555) 123-4567" ], contact.phones
  end

  test "escapes special characters in generated fields" do
    contact = create_contact(given_name: "Semi;colon", family_name: "Com,ma", organization: "Back\\slash")

    assert_equal "Semi;colon", contact.given_name
    assert_equal "Com,ma", contact.family_name
    assert_equal "Back\\slash", contact.organization
  end

  test "an organization-only contact shows as a company" do
    contact = create_contact(organization: "Acme")

    assert_equal "Acme", contact.display_name
    assert_equal "COMPANY", contact.card.value("X-ABSHOWAS")
  end

  test "sorts by family name, then given name, with organization-only contacts by organization" do
    create_contact(given_name: "Zed", family_name: "Adams")
    create_contact(given_name: "Amy", family_name: "Baker")
    create_contact(organization: "Acme")
    create_contact(given_name: "Bob", family_name: "Adams")
    create_contact(organization: "Zeta Corp")

    assert_equal [ "Acme", "Bob Adams", "Zed Adams", "Amy Baker", "Zeta Corp" ], @book.contacts.sorted.map(&:display_name)
  end

  test "changes the address book ctag and the contact etag when the vCard changes" do
    contact = create_contact(given_name: "Ada")
    ctag = @book.reload.ctag
    etag = contact.etag

    contact.update!(vcard: contact.vcard.sub("FN:Ada", "FN:Ada L"))

    assert_operator @book.reload.ctag, :>, ctag
    assert_not_equal etag, contact.etag
  end

  test "a malformed vCard is invalid" do
    contact = @book.contacts.new(uid: "bad", resource_name: "bad.vcf", vcard: "nope")
    assert_not contact.valid?
    assert contact.errors[:vcard].any?
  end
end
