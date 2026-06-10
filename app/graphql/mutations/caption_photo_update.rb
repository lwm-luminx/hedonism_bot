# frozen_string_literal: true

module Mutations
  class CaptionPhotoUpdate < BaseMutation
    description "Updates a caption_photo by id"

    field :photo, Types::PhotoType, null: false

    argument :id, ID, required: true
    argument :caption, String, required: true
    argument :description, String, required: true

    def resolve(id:, caption:, description:)
      caption_photo = GlobalID::Locator.locate(id) #: Photo

      caption_photo.update(caption: caption, description: description)
      { photo: caption_photo }
    end
  end
end
