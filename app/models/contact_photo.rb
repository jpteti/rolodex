# Reads and writes the PHOTO property. Apple clients send vCard 3.0 inline photos
# (PHOTO;ENCODING=b;TYPE=JPEG:<base64>); vCard 4.0 uses a data: URI.
class ContactPhoto
  MAX_SIZE = 512
  UPLOAD_LIMIT = 15.megabytes
  CONTENT_TYPES = { "JPEG" => "image/jpeg", "JPG" => "image/jpeg", "PNG" => "image/png", "GIF" => "image/gif",
                    "HEIC" => "image/heic", "WEBP" => "image/webp" }.freeze

  class InvalidImage < StandardError; end

  Image = Data.define(:data, :content_type)

  # Returns the embedded photo as an Image, or nil when there is none or it is a remote URI.
  def self.read(card)
    property = card["PHOTO"] or return
    value = property.value.delete(" \t")

    if (match = value.match(/\Adata:([\w\/+.-]+)?(;base64)?,(.*)\z/m))
      data = match[2] ? Base64.decode64(match[3]) : CGI.unescape(match[3])
      Image.new(data, match[1] || "application/octet-stream")
    elsif property.param("ENCODING")&.casecmp?("b") || property.param("ENCODING")&.casecmp?("base64")
      type = property.param_values("TYPE").map(&:upcase).find { |t| CONTENT_TYPES.key?(t) }
      Image.new(Base64.decode64(value), CONTENT_TYPES.fetch(type, "image/jpeg"))
    end
  end

  # Resizes an uploaded image to fit MAX_SIZE pixels and embeds it as a JPEG.
  def self.write(card, io)
    jpeg = resize(io)
    property = Vcard::Property.new("PHOTO", Base64.strict_encode64(jpeg), params: [ [ "ENCODING", "b" ], [ "TYPE", "JPEG" ] ])
    card["PHOTO"] ? card.replace_all("PHOTO", [ property ]) : card.properties << property
    card
  end

  def self.remove(card)
    card.delete("PHOTO")
  end

  def self.resize(io)
    raise InvalidImage, "The photo is larger than #{UPLOAD_LIMIT / 1.megabyte} MB" if io.size > UPLOAD_LIMIT

    ImageProcessing::Vips
      .source(io.path)
      .autorot
      .resize_to_limit(MAX_SIZE, MAX_SIZE)
      .convert("jpg")
      .saver(quality: 85, strip: true)
      .call
      .then { |file| File.binread(file.path).tap { file.close! } }
  rescue Vips::Error, ImageProcessing::Error => error
    raise InvalidImage, "That file is not an image Rolodex can read (#{error.message.lines.first.strip})"
  end
end
