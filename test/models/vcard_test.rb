require "test_helper"

class VcardTest < ActiveSupport::TestCase
  APPLE_CARD = File.binread(Rails.root.join("test/fixtures/files/apple_contact.vcf")).force_encoding(Encoding::UTF_8)

  test "parses properties with groups, parameters, and escaped values" do
    card = Vcard::Card.parse(APPLE_CARD)

    assert_equal "3.0", card.version
    assert_equal "1234-ABCD", card.uid
    assert_equal [ "Appleseed", "Johnny", "", "", "" ], card["N"].components
    assert_equal "item1", card["EMAIL"].group
    assert_equal %w[internet pref], card["EMAIL"].types
    assert_equal "Line one\nLine two, with comma; and semicolon", card.value("NOTE")
    assert_equal [ "", "", "1 Infinite Loop", "Cupertino", "CA", "95014", "USA" ], card["ADR"].components
  end

  test "reads Apple custom labels" do
    card = Vcard::Card.parse(APPLE_CARD)

    assert_equal "other", card.label_for(card["EMAIL"])
    assert_equal "Burner", card.label_for(card["TEL"])
  end

  test "writing a parsed card keeps every property and value" do
    card = Vcard::Card.parse(APPLE_CARD)
    reparsed = Vcard::Card.parse(card.to_s)

    assert_equal card.properties.map { |p| [ p.group, p.name, p.params, p.value ] },
      reparsed.properties.map { |p| [ p.group, p.name, p.params, p.value ] }
    assert_includes card.to_s, "X-SOCIALPROFILE;TYPE=twitter:x-apple:johnny"
  end

  test "folds long lines at 75 octets and unfolds them back" do
    note = "é" * 100
    card = Vcard::Card.new([ Vcard::Property.new("NOTE", note) ])
    text = card.to_s

    assert text.lines.all? { |line| line.chomp.bytesize <= 75 }
    assert_equal note, Vcard::Card.parse(text).value("NOTE")
  end

  test "escape and unescape round trip" do
    value = "a\\b, c; d\ne"
    assert_equal value, Vcard.unescape(Vcard.escape(value))
  end

  test "split returns each card in a multi-card file" do
    two = APPLE_CARD + "BEGIN:VCARD\nVERSION:3.0\nFN:Second\nEND:VCARD\n"
    cards = Vcard.split(two)

    assert_equal 2, cards.size
    assert_equal "Second", Vcard::Card.parse(cards.last).value("FN")
  end

  test "rejects text that is not a single vCard" do
    assert_raises(Vcard::ParseError) { Vcard::Card.parse("hello") }
    assert_raises(Vcard::ParseError) { Vcard::Card.parse("BEGIN:VCARD\r\nFN:x\r\n") }
    assert_raises(Vcard::ParseError) { Vcard::Card.parse("BEGIN:VCARD\r\nno colon here\r\nEND:VCARD\r\n") }
  end

  test "parses quoted parameter values containing separators" do
    property = Vcard::Property.parse(%(ADR;LABEL="1 Main St; Suite 2":;;1 Main St;;;;))
    assert_equal "1 Main St; Suite 2", property.param("LABEL")
    assert_equal ";;1 Main St;;;;", property.value
  end
end
