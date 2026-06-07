require "mini_exiftool"
require "celery"

class PhotoMetadataJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :default

  def perform(photo_id)
    photo = Photo.find(photo_id)
    image = photo.metadata_image

    return unless image

    data = image.open do |file|
      MiniExiftool.new(file)
    end

    logger.info "Photo Metadata => #{data.to_hash}"

    photo.exif_metadata = data.to_hash
    photo.taken_at = data.date_time_original
    photo.folder_date = (photo.taken_at - 3.hours).to_date
    photo.save

    if photo.has_format? "image/jpeg"
      FaceDetectionJob.perform_later photo
    end
  end
end
