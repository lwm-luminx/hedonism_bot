# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :photo_face_update, mutation: Mutations::FacialRecognitionPhotoUpdate
  end
end
