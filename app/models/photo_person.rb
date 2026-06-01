class PhotoPerson < ApplicationRecord
  self.table_name = "photo_people"

  belongs_to :photo
  belongs_to :person

  validates :person_id, uniqueness: { scope: :photo_id }
end
