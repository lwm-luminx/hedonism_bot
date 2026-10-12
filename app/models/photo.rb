class Photo < ApplicationRecord
  belongs_to :album
  has_many :processed_takes, -> { processed.order(:id) }, class_name: "PhotoTake"
  has_many :photo_takes
  # Shares with AudienceKit audiences; deleting the photo leaves them as tombstones (PhotographyPublication).
  has_many :photography_publications, dependent: nil
  before_destroy :tombstone_publications

  # The price buyers pay for a take of this photo: integer cents in a three-letter currency (USD by default), the
  # AudienceKit Money shape, so no float rounding reaches a receipt.
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be a three-letter code" }

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    album&.photographer_id
  end

  # Whether a take of this photo is served by /previews/:id: a live grant of the owning photographer shares it.
  def published?
    PhotographyGrant.active.joins(:photographer).merge(Photographer.active).where(photographer_id: owner_photographer_id)
                    .joins(:photography_publications).merge(PhotographyPublication.live.where(photo_key: id)).exists?
  end

  private

  def tombstone_publications
    PhotographyPublication.tombstone_all(photography_publications, detach_photo: true)
  end
end
