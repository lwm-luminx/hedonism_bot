# frozen_string_literal: true

module Mutations
  class UpdatePhotoFacialRecognition < BaseMutation
    description "Updates a PhotoTake by id"

    field :photo, ::Types::PhotoType, null: false

    argument :id, ID, "The ID of the photo to update", required: true
    argument :faces, [ ::Types::FaceDataInputType ], "The new facial recognition data for the photo", required: true

    def resolve(id:, faces:)
      photo = Photo.find(GlobalID.parse(id).model_id)
      photo.facial_metadata = faces

      photo.update_faces(faces)

      { photo: photo }
    end
  end
end
