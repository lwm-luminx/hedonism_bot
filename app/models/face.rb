class Face < ApplicationRecord
  belongs_to :photographer
  has_many :photo_faces, dependent: :nullify
  has_many :photo_takes, through: :photo_faces

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    photographer_id
  end

  scope :for_photographer, ->(photographer) { where(photographer: photographer) }
  scope :in_album, ->(album_id) { where(id: joins(photo_takes: :photo).where(photos: { album_id: album_id }).select(:id)) }
  scope :with_embedding, -> { where.not(embedding: nil) }
  scope :with_preview_image, -> { includes(photo_faces: { face_image_attachment: :blob }) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true

  def photo_count
    photo_faces.size
  end
end
