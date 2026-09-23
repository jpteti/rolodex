require "test_helper"

class PhotosTest < ActionDispatch::IntegrationTest
  BOOK = "/dav/addressbooks/owner/contacts/".freeze

  setup do
    sign_in_as users(:owner)
    @contact = create_contact(given_name: "Ada", family_name: "Lovelace")
  end

  def image_upload(width: 1600, height: 1200, format: "png")
    path = Rails.root.join("tmp/test-photo-#{SecureRandom.hex(4)}.#{format}")
    (Vips::Image.black(width, height, bands: 3) + [ 200, 120, 40 ]).cast(:uchar).write_to_file(path.to_s)
    Rack::Test::UploadedFile.new(path, "image/#{format}")
  end

  test "contacts without a photo show initials" do
    get contacts_url
    assert_select "#contacts .avatar--initials", "AL"
    get contact_url(@contact)
    assert_select ".avatar--initials", "AL"
    get contact_photo_url(@contact)
    assert_response :not_found
  end

  test "uploading resizes the image and embeds it as a JPEG" do
    patch contact_photo_url(@contact), params: { photo: { file: image_upload } }
    assert_redirected_to edit_contact_url(@contact)

    @contact.reload
    assert @contact.has_photo?
    photo = @contact.card["PHOTO"]
    assert_equal [ [ "ENCODING", "b" ], [ "TYPE", "JPEG" ] ], photo.params

    image = Vips::Image.new_from_buffer(@contact.photo.data, "")
    assert_equal [ 512, 384 ], [ image.width, image.height ]
    assert_equal "image/jpeg", @contact.photo.content_type

    get contact_url(@contact)
    assert_select "img.avatar[src^='#{contact_photo_path(@contact)}']"
    get contact_photo_url(@contact)
    assert_response :success
    assert_equal "image/jpeg", response.media_type
    assert_equal @contact.photo.data.b, response.body.b
  end

  test "replacing and removing a photo" do
    patch contact_photo_url(@contact), params: { photo: { file: image_upload } }
    first = @contact.reload.photo.data

    patch contact_photo_url(@contact), params: { photo: { file: image_upload(width: 300, height: 300) } }
    second = @contact.reload.photo.data
    assert_not_equal first, second
    assert_equal 1, @contact.card.all("PHOTO").size
    assert_equal 300, Vips::Image.new_from_buffer(second, "").width

    delete contact_photo_url(@contact)
    assert_not @contact.reload.has_photo?
    assert_nil @contact.card["PHOTO"]
  end

  test "a file that is not an image is rejected and changes nothing" do
    path = Rails.root.join("tmp/not-an-image.png")
    File.write(path, "hello")
    vcard = @contact.vcard

    patch contact_photo_url(@contact), params: { photo: { file: Rack::Test::UploadedFile.new(path, "image/png") } }
    follow_redirect!
    assert_select ".flash--alert", /not an image/
    assert_equal vcard, @contact.reload.vcard
  end

  test "a photo set on a device shows in the web UI, and a web photo reaches devices" do
    jpeg = Vips::Image.black(64, 64).jpegsave_buffer
    card = <<~VCF.gsub("\n", "\r\n")
      BEGIN:VCARD
      VERSION:3.0
      N:Photo;Device;;;
      FN:Device Photo
      PHOTO;ENCODING=b;TYPE=JPEG:#{Base64.strict_encode64(jpeg)}
      UID:DEVICE-PHOTO
      END:VCARD
    VCF
    dav :put, "#{BOOK}device.vcf", body: card, headers: { "Content-Type" => "text/vcard" }
    contact = Contact.find_by!(uid: "DEVICE-PHOTO")

    get contact_photo_url(contact)
    assert_equal jpeg.b, response.body.b

    patch contact_photo_url(@contact), params: { photo: { file: image_upload } }
    dav :get, "#{BOOK}#{@contact.resource_name}"
    assert_equal @contact.reload.photo.data, ContactPhoto.read(Vcard::Card.parse(response.body)).data
  end

  test "vCard 4.0 data URI photos are read" do
    png = Vips::Image.black(8, 8).pngsave_buffer
    card = Vcard::Card.new([ Vcard::Property.new("PHOTO", "data:image/png;base64,#{Base64.strict_encode64(png)}") ])
    photo = ContactPhoto.read(card)

    assert_equal "image/png", photo.content_type
    assert_equal png.b, photo.data.b
  end
end
