# Read-only access to explicitly published photos for one photographer and AudienceKit audience. A grant can expire
# (expires_at) and can be revoked at once; either stops its token.
class PhotographyGrant < ApplicationRecord
  TOKEN_PREFIX = "hbpg_"

  belongs_to :photographer
  has_many :photography_publications, dependent: :destroy
  has_many :photos, through: :photography_publications

  validates :audience_id, :token_digest, presence: true
  validates :audience_id, format: { with: /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i }

  scope :active, -> { where(revoked_at: nil).where("photography_grants.expires_at IS NULL OR photography_grants.expires_at > ?", Time.current) }

  def self.issue!(photographer:, audience_id:, expires_at: nil)
    token = "#{TOKEN_PREFIX}#{SecureRandom.base58(40)}"
    grant = create!(photographer: photographer, audience_id: audience_id, expires_at: expires_at,
                    token_digest: Digest::SHA256.hexdigest(token))
    [ grant, token ]
  end

  def self.authenticate(token)
    return unless token.is_a?(String) && token.start_with?(TOKEN_PREFIX)

    active.joins(:photographer).merge(Photographer.active).find_by(token_digest: Digest::SHA256.hexdigest(token))
  end

  # AudienceKit audience ids are UUIDs; they compare case-insensitively.
  def for_audience?(id)
    id.is_a?(String) && audience_id.casecmp?(id)
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at.future?)
  end

  # Shares `photo` with the audience, reviving a tombstone if it was shared before.
  def publish!(photo)
    publication = photography_publications.find_by(photo_key: photo.id)
    return photography_publications.create!(photo: photo) unless publication

    publication.republish!(photo) if publication.removed?
    publication
  end

  def unpublish!(photo)
    photography_publications.live.where(photo_key: photo.id).find_each(&:remove!)
  end

  # The publications AudienceKit pages through, in keyset order (published_at, photo_key). Without `updated_since`,
  # only photos it can show: still shared, still the photographer's and with a processed take. With it, every row
  # changed since then, tombstones included, so a consumer can catch up without a full crawl.
  def publications(updated_since: nil)
    scope = photography_publications.includes(photo: { processed_takes: { images_attachments: :blob } })
    return scope.changed_since(updated_since) if updated_since

    scope.live.joins(photo: :album).where(albums: { photographer_id: photographer_id })
         .where(photos: { id: PhotoTake.processed.select(:photo_id) })
  end

  # Whether `photo`, as it is now, is shared with this grant.
  def shows?(photo)
    photo.owner_photographer_id == photographer_id && photography_publications.live.exists?(photo_key: photo.id)
  end
end
