# Read-only access to explicitly published photos for one photographer and AudienceKit audience.
class PhotographyGrant < ApplicationRecord
  belongs_to :photographer
  has_many :photography_publications, dependent: :destroy
  has_many :photos, through: :photography_publications

  validates :audience_id, :token_digest, presence: true
  validates :audience_id, format: { with: /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i }

  def self.issue!(photographer:, audience_id:)
    token = "hbpg_#{SecureRandom.base58(40)}"
    [ create!(photographer: photographer, audience_id: audience_id, token_digest: Digest::SHA256.hexdigest(token)), token ]
  end

  def self.authenticate(token)
    return unless token.is_a?(String) && token.start_with?("hbpg_")

    joins(:photographer).merge(Photographer.active).find_by(token_digest: Digest::SHA256.hexdigest(token), revoked_at: nil)
  end

  def published_photos
    photos.joins(:album).where(albums: { photographer_id: photographer_id })
      .where(id: PhotoTake.processed.select(:photo_id))
      .includes(processed_takes: { images_attachments: :blob }).order(:id)
  end
end
