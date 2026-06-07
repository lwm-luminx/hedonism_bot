class FacePreviewExtractJob < ApplicationJob
  queue_as :default

  def perform(person_photo)
    face_image = person_photo.photo.images.select { |img| img.content_type == "image/jpeg" }.first

    face_image.open do |file|
      processed_file = ImageProcessing::Vips
                         .source(file.path)
                         .crop(person_photo.bounding_box['x'],
                               person_photo.bounding_box['y'],
                               person_photo.bounding_box['w'],
                               person_photo.bounding_box['h'])
                         .call

      person_photo.face_image.purge
      person_photo.face_image.attach io: processed_file, filename: "#{person_photo.id}_face_preview.jpg"
      person_photo.save
    end
  end
end
