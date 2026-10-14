# One logical Photo shared with an AudienceKit audience through a grant. Unpublishing keeps the row as a tombstone
# (removed_at) so AudienceKit, which pulls `photos(updatedSince:)`, learns about the removal; photo_key is the id the
# photo was shared under and outlives the photo itself (the FK nullifies on delete).
class PhotographyPublication < ApplicationRecord
  belongs_to :photography_grant
  belongs_to :photo, optional: true

  before_validation :remember_photo, on: :create
  validates :photo_key, :published_at, presence: true
  validate :same_photographer, on: :create

  scope :live, -> { where(removed_at: nil) }
  # Rows AudienceKit has not seen since `since`, tombstones included.
  scope :changed_since, ->(since) { where(updated_at: since..) }

  # Marks `publications` removed in one statement, keeping their photo_key; a deleted photo's rows lose photo_id.
  def self.tombstone_all(publications, detach_photo: false)
    changes = { removed_at: Time.current, updated_at: Time.current }
    changes[:photo_id] = nil if detach_photo
    publications.live.update_all(changes) # rubocop:disable Rails/SkipsModelValidations
  end

  def removed?
    removed_at.present?
  end

  def remove!
    update!(removed_at: Time.current) unless removed?
  end

  # Shares the photo again after a removal: a new published_at so it reappears at the end of the keyset order.
  def republish!(photo)
    update!(photo: photo, removed_at: nil, published_at: Time.current)
  end

  private

  def remember_photo
    self.photo_key ||= photo&.id
    self.published_at ||= Time.current
  end

  def same_photographer
    return if photo && photography_grant && photo.owner_photographer_id == photography_grant.photographer_id

    errors.add(:photo, "must belong to the grant's photographer")
  end
end
