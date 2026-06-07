require "image_processing/vips"

class PhotoToJpegJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find(photo_id)
    heif_image = photo.composite_image

    return unless heif_image

    # Check if a jpeg version already exists
    return if photo.has_format? "image/jpeg"

    heif_image.open do |file|
      processed_file = ImageProcessing::Vips
        .source(file.path)
        .convert("jpeg")
        .call

      photo.attach_format "image/jpeg", processed_file, filename: "#{heif_image.filename.base}.jpg"

      photo.save
    end

    FaceDetectionJob.perform_later photo
  end
end
