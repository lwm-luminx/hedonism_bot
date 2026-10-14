# frozen_string_literal: true

module Types
  class AlbumStorageType < Types::BaseObject
    description "Storage used by one album's photos"

    field :album_id, ID, null: false, description: "The album's global ID (the Folder ID)"
    field :name, String, null: false, description: "The album's name"
    field :photo_count, Integer, null: false, description: "Number of photo takes in the album"
    field :bytes, GraphQL::Types::BigInt, null: false, description: "Bytes stored for the album, originals and previews"
    field :original_bytes, GraphQL::Types::BigInt, null: false, description: "Bytes of original files (RAW and camera HEIF/JPEG)"
    field :archived_bytes, GraphQL::Types::BigInt, null: false, description: "Bytes of originals in archive storage"
    field :transition, Types::StorageTransitionType, null: true, description: "A tier move in progress, if any"

    def album_id
      HedonismBotSchema.id_from_object(@object.album, Types::FolderType, context)
    end

    def transition
      @object.storage_transition
    end
  end
end
