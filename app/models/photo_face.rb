class PhotoFace < ApplicationRecord
  belongs_to :photo_take

  belongs_to :face, optional: true

  has_one_attached :face_image
  scope :with_preview_image, -> { includes(face_image_attachment: :blob).joins(face_image_attachment: :blob) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true
end
