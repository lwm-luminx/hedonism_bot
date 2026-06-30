# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :update_photo_promise_file_update, mutation: Mutations::UpdatePhotoPromiseFileUpdate
    field :create_photo_promise, mutation: Mutations::CreatePhotoPromise
    field :attach_photo_promise_files, mutation: Mutations::AttachPhotoPromiseFiles
    field :update_photo_caption, mutation: Mutations::UpdatePhotoCaption
    field :update_photo_face, mutation: Mutations::UpdatePhotoFacialRecognition
  end
end
