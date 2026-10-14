# frozen_string_literal: true

# A single music track for those pages for a DJ or other music facet
class Track < ApplicationRecord
  belongs_to :social_link
  belongs_to :waveform_image, class_name: "Image"

  validates :waveform, presence: true
  validates :artwork, presence: true
end
