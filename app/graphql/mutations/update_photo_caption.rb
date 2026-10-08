# frozen_string_literal: true

module Mutations
  class UpdatePhotoCaption < BaseMutation
    description "Updates a caption_photo by id"

    field :photo, Types::PhotoType, null: false

    argument :id, ID, "The ID of the photo to update", required: true
    argument :caption, String, "The new caption for the photo", required: true
    argument :description, String, "The new description for the photo", required: true

    def resolve(id:, caption:, description:)
      caption_photo = HedonismBotSchema.object_from_id(id, context) #: PhotoTake
      raise GraphQL::ExecutionError, "Photo not found" unless caption_photo.is_a?(PhotoTake)

      caption = caption || caption_photo.caption
      description = description || caption_photo.description

      caption_photo.update(caption: caption, description: description)
      { photo: caption_photo }
    end
  end
end
