# frozen_string_literal: true

module Types
  class StorageUsageType < Types::BaseObject
    description "Storage used by a photographer's photos"

    field :total_bytes, GraphQL::Types::BigInt, null: false, description: "All bytes stored"
    field :hot_bytes, GraphQL::Types::BigInt, null: false, description: "Bytes in standard storage"
    field :archived_bytes, GraphQL::Types::BigInt, null: false, description: "Bytes in archive storage"
    field :archive_available, Boolean, null: false, method: :archive_available?,
      description: "Whether an archive storage service is configured"
    field :albums, [ Types::AlbumStorageType ], null: false, description: "Usage per album, by name"
  end
end
