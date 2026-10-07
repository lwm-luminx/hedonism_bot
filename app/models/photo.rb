class Photo < ApplicationRecord
  belongs_to :album
  has_many :photo_takes

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    album&.photographer_id
  end
end
