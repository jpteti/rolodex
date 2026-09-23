require "test_helper"

class ContactEditorTest < ActiveSupport::TestCase
  CARD = File.binread(Rails.root.join("test/fixtures/files/apple_contact.vcf")).force_encoding(Encoding::UTF_8)

  def edit(text, **changes)
    editor = ContactEditor.new(Vcard::Card.parse(text))
    params = form_params(editor).deep_merge(changes.deep_stringify_keys)
    editor.assign(params.with_indifferent_access)
    editor.to_vcard(text)
  end

  # What the browser submits for an untouched form.
  def form_params(editor)
    ContactEditor::SINGLE_FIELDS.to_h { |field| [ field.to_s, editor.public_send(field).to_s ] }.merge(
      ContactEditor::REPEATED.keys.to_h do |field|
        [ field.to_s, editor.public_send(field).each_with_index.to_h { |row, index| [ index.to_s, row.to_h.transform_keys(&:to_s).compact ] } ]
      end
    )
  end

  test "loads fields and labels from an Apple vCard" do
    editor = ContactEditor.new(Vcard::Card.parse(CARD))

    assert_equal "Johnny", editor.given_name
    assert_equal "Appleseed", editor.family_name
    assert_equal "Apple Inc.", editor.organization
    assert_equal "Line one\nLine two, with comma; and semicolon", editor.note
    assert_equal [ [ "other", "johnny@example.com" ] ], editor.emails.map { |row| [ row.label, row.value ] }
    assert_equal [ [ "Burner", "(555) 123-4567" ] ], editor.phones.map { |row| [ row.label, row.value ] }
    assert_equal "home", editor.addresses.first.label
    assert_equal [ "1 Infinite Loop", "Cupertino", "CA", "95014", "USA" ],
      ContactEditor::ADDRESS_PARTS.map { |part| editor.addresses.first[part] }
  end

  test "saving an untouched form returns the original text byte for byte" do
    assert_equal CARD, edit(CARD)
  end

  test "editing one field leaves every other property unchanged" do
    result = Vcard::Card.parse(edit(CARD, job_title: "Gardener"))
    original = Vcard::Card.parse(CARD)

    assert_equal "Gardener", result.value("TITLE")
    kept = original.properties.map(&:to_s)
    assert_equal kept, result.properties.reject { |p| p.name == "TITLE" }.map(&:to_s)
  end

  test "renaming updates N and FN and keeps extra N components" do
    card = CARD.sub("N:Appleseed;Johnny;;;", "N:Appleseed;Johnny;;;;Extra")
    result = Vcard::Card.parse(edit(card, given_name: "John", middle_name: "Q", prefix: "Mr."))

    assert_equal [ "Appleseed", "John", "Q", "Mr.", "", "Extra" ], result["N"].components
    assert_equal "Mr. John Q Appleseed", result.value("FN")
  end

  test "organization edits keep the department component" do
    result = Vcard::Card.parse(edit(CARD, organization: "Apple"))
    assert_equal [ "Apple", "Engineering" ], result["ORG"].components
  end

  test "custom labels round-trip, and changing a label rewrites only the label" do
    result = Vcard::Card.parse(edit(CARD, phones: { "0" => { label: "Work cell" } }))
    phone = result["TEL"]

    assert_equal "Work cell", result.label_for(phone)
    assert_equal "(555) 123-4567", phone.text
    assert_equal "item2", phone.group
    assert_equal 1, result.all("X-ABLABEL").count { |p| p.group == "item2" }
  end

  test "standard labels become TYPE parameters and drop the custom label" do
    result = Vcard::Card.parse(edit(CARD, phones: { "0" => { label: "mobile" } }))
    phone = result["TEL"]

    assert_equal "mobile", result.label_for(phone)
    assert_includes phone.param_values("TYPE").map(&:upcase), "CELL"
    assert_empty result.all("X-ABLABEL").select { |p| p.group == "item2" }
  end

  test "new rows get default types and labels" do
    result = Vcard::Card.parse(edit(CARD, emails: { "17000001" => { label: "work", value: "j@work.example" } },
      urls: { "17000002" => { label: "Blog", value: "https://blog.example" } }))

    work = result.all("EMAIL").find { |p| p.text == "j@work.example" }
    assert_equal %w[INTERNET WORK], work.param_values("TYPE")
    url = result["URL"]
    assert_equal "https://blog.example", url.value
    assert_equal "Blog", result.label_for(url)
    assert_equal 2, result.all("EMAIL").size
  end

  test "removing a row removes its property and Apple's helper properties in the same group" do
    result = Vcard::Card.parse(edit(CARD, addresses: { "0" => { street: "", city: "", region: "", postal_code: "", country: "" } }))

    assert_nil result["ADR"]
    assert_empty result.properties.select { |p| p.group == "item3" }
    assert result["X-SOCIALPROFILE"]
  end

  test "address edits keep the post office box and extended components" do
    card = CARD.sub("item3.ADR;type=HOME:;;1 Infinite Loop", "item3.ADR;type=HOME:PO 9;Suite 5;1 Infinite Loop")
    result = Vcard::Card.parse(edit(card, addresses: { "0" => { city: "San Jose" } }))

    assert_equal [ "PO 9", "Suite 5", "1 Infinite Loop", "San Jose", "CA", "95014", "USA" ], result["ADR"].components
    assert_equal "us", result.value("X-ABADR")
  end

  test "birthdays with and without a year" do
    with_year = Vcard::Card.parse(edit(CARD, birthday: "1990-05-10"))
    assert_equal "1990-05-10", with_year.value("BDAY")

    no_year = Vcard::Card.parse(edit(CARD, birthday: "05-10"))
    assert_equal "1604-05-10", no_year.value("BDAY")
    assert_equal "1604", no_year["BDAY"].param("X-APPLE-OMIT-YEAR")
    assert_equal "05-10", ContactEditor.new(no_year).birthday

    assert_nil Vcard::Card.parse(edit(no_year.to_s, birthday: ""))["BDAY"]
  end

  test "an invalid birthday is an error" do
    editor = ContactEditor.new(Vcard::Card.parse(CARD)).assign({ birthday: "May 10" })
    assert_not editor.valid?
  end

  test "multi-line notes are escaped" do
    result = Vcard::Card.parse(edit(CARD, note: "First\r\nSecond, third"))
    assert_equal "First\nSecond, third", result.value("NOTE")
  end

  test "a new company-only contact is marked as a company" do
    editor = ContactEditor.blank(uid: "U1").assign({ organization: "Acme" })
    card = Vcard::Card.parse(editor.to_vcard)

    assert_equal "Acme", card.value("FN")
    assert_equal "COMPANY", card.value("X-ABSHOWAS")
    assert_equal "U1", card.uid
  end
end
