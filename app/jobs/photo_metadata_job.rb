require "mini_exiftool"
require "celery"

class PhotoMetadataJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :default

  def perform(photo_take)
    image = photo_take.raw_image

    return unless image

    data = image.open do |file|
      MiniExiftool.new(file)
    end

    logger.info "PhotoTake Metadata => #{data.to_hash}"

    photo_take.exif_metadata = data.to_hash
    photo_take.taken_at = data.date_time_original
    photo_take.save
  end
end
