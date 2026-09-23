require "test_helper"

class ImportTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  PHOTO = Base64.strict_encode64("\xFF\xD8\xFF\xE0fake-jpeg-bytes".b * 20)

  setup do
    sign_in_as users(:owner)
    @existing = create_contact(given_name: "Old", family_name: "Name")
  end

  def vcf_upload(text)
    path = Rails.root.join("tmp/import-#{SecureRandom.hex(4)}.vcf")
    File.binwrite(path, text)
    Rack::Test::UploadedFile.new(path, "text/vcard")
  end

  def export_text
    folded_photo = "PHOTO;ENCODING=b;TYPE=JPEG:#{PHOTO}".scan(/.{1,74}/).join("\r\n ")
    [
      "BEGIN:VCARD\r\nVERSION:3.0\r\nN:Curie;Marie;;;\r\nFN:Marie Curie\r\nX-CUSTOM:kept\r\n#{folded_photo}\r\nUID:CURIE-1\r\nEND:VCARD\r\n",
      "BEGIN:VCARD\r\nVERSION:3.0\r\nN:Noether;Emmy;;;\r\nFN:Emmy Noether\r\nEND:VCARD\r\n",
      "BEGIN:VCARD\r\nVERSION:3.0\r\nN:Name;New;;;\r\nFN:New Name\r\nUID:#{@existing.uid}\r\nEND:VCARD\r\n",
      "BEGIN:VCARD\r\nVERSION:3.0\r\nthis line has no colon\r\nEND:VCARD\r\n",
      "BEGIN:VCARD\nVERSION:3.0\nN:Franklin;Rosalind;;;\nFN:Rosalind Franklin\nUID:FRANKLIN-1\nEND:VCARD\n"
    ].join
  end

  test "the upload returns at once and a background job imports the cards" do
    assert_enqueued_jobs 1, only: ImportJob do
      assert_no_difference -> { Contact.count } do
        post imports_url, params: { import: { file: vcf_upload(export_text) } }
      end
    end
    import = Import.last
    assert_redirected_to import_url(import)

    follow_redirect!
    assert_select "meta[http-equiv=refresh]"
    assert_select "#import_status", /Importing/

    perform_enqueued_jobs
    get import_url(import)
    assert_select "meta[http-equiv=refresh]", count: 0
    assert_select "#created_count", "3"
    assert_select "#updated_count", "1"
    assert_select "#failed_count", "1"
    assert_select "#import_failures li", text: /Card 4.*Missing ':'/m
  end

  test "each vCard becomes a contact that keeps its raw text" do
    post imports_url, params: { import: { file: vcf_upload(export_text) } }
    perform_enqueued_jobs

    curie = Contact.find_by!(uid: "CURIE-1")
    assert_includes curie.vcard, "X-CUSTOM:kept"
    assert_includes curie.vcard, "\r\n PHOTO".strip.empty? ? "" : "\r\n "
    assert_equal export_text.split("END:VCARD\r\n").first + "END:VCARD\r\n", curie.vcard
    assert curie.has_photo?
    assert_equal "CURIE-1.vcf", curie.resource_name
    assert_equal "Rosalind Franklin", Contact.find_by!(uid: "FRANKLIN-1").display_name
  end

  test "a matching UID updates the existing contact instead of duplicating it" do
    post imports_url, params: { import: { file: vcf_upload(export_text) } }
    perform_enqueued_jobs

    assert_equal 1, Contact.where(uid: @existing.uid).count
    assert_equal "New Name", @existing.reload.display_name
  end

  test "vCards without a UID get a generated one" do
    post imports_url, params: { import: { file: vcf_upload(export_text) } }
    perform_enqueued_jobs

    emmy = Contact.find_by!(display_name: "Emmy Noether")
    assert_match(/\A[0-9A-F-]{36}\z/, emmy.uid)
    assert_equal emmy.uid, Vcard::Card.parse(emmy.vcard).uid
  end

  test "importing the same file twice updates instead of duplicating" do
    2.times do
      post imports_url, params: { import: { file: vcf_upload(export_text.sub(/.*?END:VCARD\r\n.*?END:VCARD\r\n/m, "")) } }
      perform_enqueued_jobs
    end
    assert_equal 1, Contact.where(uid: "FRANKLIN-1").count
    assert_equal 2, Import.last.updated_count
  end

  test "a request without a file shows an error" do
    post imports_url, params: {}
    assert_redirected_to new_import_url
  end

  test "another user's import is not visible" do
    other = User.create!(username: "other")
    import = other.address_book.imports.create!(filename: "x.vcf", source: "")
    get import_url(import)
    assert_response :not_found
  end
end
