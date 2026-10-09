require "mini_exiftool"

class PhotoMetadataJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :default

  def perform(photo_take)
    image = photo_take.raw_image.presence || photo_take.metadata_image

    return unless image

    data = image.open do |file|
      MiniExiftool.new(file)
    end

    logger.info "PhotoTake Metadata => #{data.to_hash}"

    photo_take.exif_metadata = data.to_hash
    photo_take.taken_at = data.date_time_original
    # EXIF without an offset cannot safely be compared with UTC phone timestamps.
    offset = data.offset_time_original
    if data.date_time_original && offset.to_s.match?(/\A[+-]\d{2}:\d{2}\z/)
      capture_time = Time.strptime("#{data.date_time_original.strftime('%Y-%m-%d %H:%M:%S')} #{offset}", "%Y-%m-%d %H:%M:%S %:z")
      photo_take.taken_at = capture_time
      recordings = photo_take.photo_promise_files.includes(:photo_promise).flat_map { |file| file.photo_promise.location_recordings }
      photo_take.inferred_venue = ShootLocationHistory.venue_at(recordings, capture_time)
    end
    photo_take.save!
  end
end
