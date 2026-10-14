class Album < ApplicationRecord
  belongs_to :photographer
  belongs_to :event, optional: true
  belongs_to :venue, optional: true

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    photographer_id
  end

  has_many :photos
  has_many :photo_takes, through: :photos
end
