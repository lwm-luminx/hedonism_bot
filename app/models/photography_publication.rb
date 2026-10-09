class PhotographyPublication < ApplicationRecord
  belongs_to :photography_grant
  belongs_to :photo
  validate :same_photographer

  private

  def same_photographer
    return if photo && photography_grant && photo.owner_photographer_id == photography_grant.photographer_id

    errors.add(:photo, "must belong to the grant's photographer")
  end
end
