module Types
  class PhotoPromiseType < Types::BaseObject
    field :id, ID, null: false
    field :photo, Types::PhotoType, null: false
  end
end
