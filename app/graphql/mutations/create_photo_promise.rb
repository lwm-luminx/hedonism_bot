# frozen_string_literal: true

module Mutations
  class CreatePhotoPromise < BaseMutation
    description "Creates a new upload photo promise"

    field :promise, Types::PhotoPromiseType, null: false

    argument :album_name, String, required: false, description: "Album the uploads go into (created if missing)"

    argument :upload_context, GraphQL::Types::JSON, required: false, description: "Event and venue supplied by the uploader"

    def resolve(album_name: nil, upload_context: nil)
      photographer = context[:photographer]
      if upload_context
        raise GraphQL::ExecutionError, "An album is required for shoot details" unless album_name.present?
        unless upload_context.is_a?(Hash) && upload_context.keys.all? { |key| %w[event venue].include?(key) } &&
               upload_context.values.all? { |value| value.is_a?(String) && value.length <= 500 }
          raise GraphQL::ExecutionError, "Invalid shoot details"
        end
      end
      album = photographer.albums.find_or_create_by!(name: album_name) if album_name.present?
      album.update!(upload_context: upload_context) if upload_context
      @promise = PhotoPromise.create(photographer: photographer, album: album)

      { promise: @promise }
    end
  end
end
