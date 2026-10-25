module Mutations
  class LinkAlbumToAudienceKit < BaseMutation
    description "Links an album to an AudienceKit event (and so its venue), or to a venue with no listed event, in one " \
                "connected audience. AudienceKit shows the album's published photos there after its next pull."

    argument :folder_id, ID, required: true, description: "The album (folder)"
    argument :audience_id, ID, required: true, description: "AudienceKit's audience id"
    argument :event_id, ID, required: false, description: "AudienceKit's event id"
    argument :venue_id, ID, required: false, description: "AudienceKit's venue id, when there is no event"

    field :folder, Types::FolderType, null: false
    field :link, Types::AlbumEventType, null: false

    def ready?(**args)
      require_uploader!
      super
    end

    def resolve(folder_id:, audience_id:, event_id: nil, venue_id: nil)
      album = context[:photographer].albums.find_by(id: GlobalID.parse(folder_id)&.model_id)
      raise GraphQL::ExecutionError, "Album not found" unless album

      link = AudienceKitCatalog.new(context[:photographer]).link!(album, audience_id: audience_id, event_id: event_id,
                                                                         venue_id: venue_id)
      { folder: album.reload, link: link }
    rescue AudienceKitCatalog::Invalid, AudienceKit::Client::Error => e
      raise GraphQL::ExecutionError, e.message
    end
  end
end
