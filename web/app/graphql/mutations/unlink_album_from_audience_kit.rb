module Mutations
  class UnlinkAlbumFromAudienceKit < BaseMutation
    description "Removes an album's AudienceKit link in one audience; AudienceKit drops its photos there after its next pull."

    argument :folder_id, ID, required: true, description: "The album (folder)"
    argument :audience_id, ID, required: true, description: "AudienceKit's audience id"

    field :folder, Types::FolderType, null: false

    def ready?(**args)
      require_uploader!
      super
    end

    def resolve(folder_id:, audience_id:)
      album = context[:photographer].albums.find_by(id: GlobalID.parse(folder_id)&.model_id)
      raise GraphQL::ExecutionError, "Album not found" unless album

      album.album_events.select { |link| link.audience_id.casecmp?(audience_id.to_s) }.each(&:destroy!)
      { folder: album.reload }
    end
  end
end
