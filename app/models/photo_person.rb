class PhotoPerson < ApplicationRecord
  self.table_name = "photo_people"

  belongs_to :photo

  belongs_to :person
end
