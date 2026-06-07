class PhotoPerson < ApplicationRecord
  self.table_name = "photo_people"

  belongs_to :photo

  belongs_to :person, optional: true

  has_one_attached :face_image
end
