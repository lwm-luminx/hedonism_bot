# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_photo_promise, mutation: Mutations::CreatePhotoPromise
    field :update_photo_caption, mutation: Mutations::UpdatePhotoCaption
    field :update_photo_face, mutation: Mutations::UpdatePhotoFacialRecognition
  end
end
