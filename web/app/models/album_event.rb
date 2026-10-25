# One album linked to an AudienceKit venue, and event if one is listed, in one audience its photographer is connected
# to. AudienceKit pulls it with each photo (the photography contract's venueId/eventId) and shows the photo there.
# Changing a link touches the album's publications to that audience, so the next photos(updatedSince:) pull sees it.
class AlbumEvent < ApplicationRecord
  UUID = /\A\h{8}-(?:\h{4}-){3}\h{12}\z/

  belongs_to :album

  validates :audience_id, :audience_kit_venue_id, presence: true, format: { with: UUID }
  validates :audience_kit_event_id, format: { with: UUID }, allow_nil: true
  validates :audience_id, uniqueness: { scope: :album_id }

  after_commit :touch_publications

  # The link a grant's publication carries, or nil when the album isn't linked in its audience.
  def self.for_grant(album, grant)
    album&.album_events&.find { |link| link.audience_id.casecmp?(grant.audience_id.to_s) }
  end

  def owner_photographer_id
    album.photographer_id
  end

  private

  def touch_publications
    grants = PhotographyGrant.where(photographer_id: album.photographer_id, audience_id:)
    PhotographyPublication.live.where(photography_grant: grants, photo_id: album.photos.select(:id))
                          .update_all(updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
