class PhotoVersion < ApplicationRecord
  VARIANTS = %w[original thumbnail small medium large web].freeze

  belongs_to :photo
  has_one_attached :file

  validates :variant, presence: true,
                      uniqueness: { scope: [ :photo_id, :format ] }

  scope :of_variant, ->(variant) { where(variant: variant) }
  scope :of_format, ->(format) { where(format: format) }
end
