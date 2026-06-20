class Photo < ApplicationRecord
  belongs_to :album
  has_many :photo_takes
end
