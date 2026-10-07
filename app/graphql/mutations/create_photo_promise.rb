# frozen_string_literal: true

module Mutations
  class CreatePhotoPromise < BaseMutation
    description "Creates a new upload photo promise"

    field :promise, Types::PhotoPromiseType, null: false

    argument :album_name, String, required: false, description: "Album the uploads go into (created if missing)"

    def resolve(album_name: nil)
      photographer = context[:photographer]
      album = photographer.albums.find_or_create_by!(name: album_name) if album_name.present?
      @promise = PhotoPromise.create(photographer: photographer, album: album)

      { promise: @promise }
    end
  end
end
