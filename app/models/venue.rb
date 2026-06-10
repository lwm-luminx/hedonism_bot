class Venue < ApplicationRecord
  belongs_to :photographer
  has_many :photos, dependent: :nullify

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :photographer_id, allow_nil: true },
            format: { with: /\A[a-z0-9][a-z0-9-]*\z/, allow_nil: true }
end
