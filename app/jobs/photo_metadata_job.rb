require 'mini_exiftool'
require 'celery'

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

    face_image = photo.composite_image
    face_image_url = rails_storage_proxy_url(face_image, expires_in: 1.minute, host: "localhost:5000")


    Celery.enqueue 'hedonism.who_dis.worker.download_convert_and_extract_facial_data', face_image_url do |result|
      photo.facial_metadata = result
      photo.photo_people.clear

      result.each do |face_result|
        photo.photo_people.create(arc_face_embedding: face_result['embedding'], bounding_box: face_result['facial_area'])
      end

      photo.save!
    end
  end
end
