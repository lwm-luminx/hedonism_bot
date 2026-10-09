class FacePreviewExtractJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(person_photo)
    PrivacyLock.biometric do
      person_photo = PhotoFace.find_by(id: person_photo.id)
      return unless person_photo && !person_photo.photo_take.face_processing_disabled?
      extract(person_photo)
    end
  end

  private

  def extract(person_photo)
    face_image = person_photo.photo_take.images.select { |image| image.content_type == "image/jpeg" }.first
    return unless face_image

    face_image.open do |file|
      processed_file = ImageProcessing::Vips
                         .source(file.path)
                         .crop(person_photo.bounding_box["x"],
                               person_photo.bounding_box["y"],
                               person_photo.bounding_box["w"],
                               person_photo.bounding_box["h"])
                         .call

      person_photo.face_image.purge
      person_photo.face_image.attach io: processed_file, filename: "#{person_photo.id}_face_preview.jpg"
      person_photo.save
    end
  end
end
