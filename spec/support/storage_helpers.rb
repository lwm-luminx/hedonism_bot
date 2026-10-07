module StorageHelpers
  # A photo take with a small RAW original, a camera HEIF original and a JPEG preview.
  def create_take_with_files(album, raw: "r" * 300, heif: "h" * 200, jpeg: "j" * 50)
    photo = Photo.create!(album: album)
    take = PhotoTake.create!(photo: photo, original_filename: "DSC1.arw", content_type: "image/x-sony-arw", file_size_bytes: raw.bytesize)
    take.raw_image.attach(io: StringIO.new(raw), filename: "DSC1.arw", content_type: "image/x-sony-arw", identify: false)
    take.images.attach(io: StringIO.new(heif), filename: "DSC1.hif", content_type: "image/heif", identify: false)
    take.images.attach(io: StringIO.new(jpeg), filename: "DSC1.jpg", content_type: "image/jpeg", identify: false)
    take
  end
end

RSpec.configure do |config|
  config.include StorageHelpers
end
