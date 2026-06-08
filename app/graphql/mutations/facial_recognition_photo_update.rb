# frozen_string_literal: true

module Mutations
  class FacialRecognitionPhotoUpdate < BaseMutation
    description "Updates a Photo by id"

    field :photo, ::Types::PhotoType, null: false

    argument :id, ID, required: true
    argument :faces, [::Types::FaceDataInputType], required: true

    def resolve(id:, faces:)
      photo = Photo.find(id)
      photo.facial_metadata = faces

      photo.update_faces(faces)

      { photo: photo }
    end
  end
end
