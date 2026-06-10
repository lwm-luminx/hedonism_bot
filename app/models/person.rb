class Person < ApplicationRecord
  belongs_to :photographer
  has_many :photo_people, dependent: :nullify
  has_many :photos, through: :photo_people

  scope :for_photographer, ->(photographer) { where(photographer: photographer) }
  scope :with_embedding, -> { where.not(embedding: nil) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true
end
