class Person < ApplicationRecord
  belongs_to :photographer
  has_many :photo_people, dependent: :nullify
  has_many :photos, through: :photo_people

  scope :for_photographer, ->(photographer) { includes(photo_people: :photo).joins(photo_people: :photo).where(photo_people: { photos: { photographer_id: photographer } }) }
  scope :with_embedding, -> { where.not(embedding: nil) }
  scope :with_preview_image, -> { includes(photo_people: { face_image_attachment: :blob }) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true

  def photo_count
    photo_people.size
  end
end
