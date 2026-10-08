# frozen_string_literal: true

module Mutations
  class UpdatePhotoFacialRecognition < BaseMutation
    description "Updates a PhotoTake by id"

    field :photo, ::Types::PhotoType, null: false

    argument :id, ID, "The ID of the photo to update", required: true
    argument :faces, [ ::Types::FaceDataInputType ], "The new facial recognition data for the photo", required: true

    def resolve(id:, faces:)
      photo = HedonismBotSchema.object_from_id(id, context) #: PhotoTake
      raise GraphQL::ExecutionError, "Photo not found" unless photo.is_a?(PhotoTake)

      photo.update_faces(faces)

      { photo: photo }
    end
  end
end
