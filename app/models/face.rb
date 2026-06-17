class Face < ApplicationRecord
  belongs_to :photographer
  has_many :photo_faces, dependent: :nullify
  has_many :photo_takes, through: :photo_faces

  scope :for_photographer, ->(photographer) { includes(photo_faces: :photo).joins(photo_faces: :photo).where(photo_faces: { photos: { photographer_id: photographer } }) }
  scope :with_embedding, -> { where.not(embedding: nil) }
  scope :with_preview_image, -> { includes(photo_faces: { face_image_attachment: :blob }) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true

  def photo_count
    photo_faces.size
  end
end
