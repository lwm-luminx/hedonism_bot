class PhotoFace < ApplicationRecord
  belongs_to :face, optional: true
  belongs_to :photo_take

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    photo_take&.owner_photographer_id
  end

  has_one_attached :face_image
  scope :with_preview_image, -> { includes(face_image_attachment: :blob).joins(face_image_attachment: :blob) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true
end
