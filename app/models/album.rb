class Album < ApplicationRecord
  belongs_to :photographer

  has_many :photos
  has_many :photo_takes, through: :photos
end
