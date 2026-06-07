# frozen_string_literal: true

module Mutations
  class CaptionPhotoUpdate < BaseMutation
    description "Updates a caption_photo by id"

    field :photo, Types::PhotoType, null: false

    argument :id, ID, required: true
    argument :caption, String, required: true

    def resolve(id:, caption:)
      caption_photo = Photo.find(id)

      caption_photo.update(caption: caption)
      { photo: caption_photo }
    end
  end
end
