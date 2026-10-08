# frozen_string_literal: true

module Mutations
  class ArchiveAlbum < BaseMutation
    description "Moves an album's photo originals to cheaper archive storage; previews stay in standard storage"

    TRANSITION = "archiving"
    DIRECTION = "archive"

    argument :id, ID, "The ID of the album (folder)", required: true

    field :album, Types::AlbumStorageType, null: false

    def ready?(**args)
      raise GraphQL::ExecutionError, "Admin sign-in required" unless context[:current_user]&.admin_of?(context[:photographer])

      super
    end

    def resolve(id:)
      album = context[:photographer].albums.find_by(id: GlobalID.parse(id)&.model_id)
      raise GraphQL::ExecutionError, "Album not found" unless album
      raise GraphQL::ExecutionError, "No archive storage is configured" unless StorageTier.archive_available?

      album.update!(storage_transition: self.class::TRANSITION)
      ArchiveAlbumJob.perform_later(album, self.class::DIRECTION)

      { album: StorageUsage.new(context[:photographer]).albums.find { |usage| usage.album.id == album.id } }
    end
  end
end
