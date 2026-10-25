# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :photographer, Types::PhotographerType, null: false, description: "The current Photographer for the request"
    field :photos, Types::PhotoTakeType.connection_type, null: false, description: "All photos for a particular Photographer" do
      argument :face_id, ID, required: false, description: "Filter photos by face ID"
      argument :folder_id, ID, required: false, description: "Filter photos by folder ID"
    end
    field :faces, Types::FaceType.connection_type, null: false, description: "All faces for a particular Photographer" do
      argument :folder_id, ID, required: false, description: "Filter faces by folder ID"
    end
    field :folders, Types::FolderType.connection_type, null: false, description: "All groupings for a particular Photographer" do
      argument :face_id, ID, required: false, description: "Filter folders by face ID"
    end
    field :events, Types::EventType.connection_type
    field :audience_kit_catalog, [ Types::AudienceKitAudienceType ], null: false,
                                                                   description: "The AudienceKit venues and events the photographer may link albums to, per connected audience" do
      argument :from, GraphQL::Types::ISO8601DateTime, required: false, description: "Events starting at or after (default 90 days ago)"
      argument :to, GraphQL::Types::ISO8601DateTime, required: false, description: "Events starting at or before (default 30 days ahead)"
      argument :query, String, required: false, description: "Matches event and venue names"
      argument :latitude, Float, required: false, description: "With longitude: venues near this point"
      argument :longitude, Float, required: false
    end
    field :venues, Types::VenueType.connection_type

    def photographer
      context[:photographer]
    end

    def faces(folder_id: nil)
      @photos = Face.for_photographer(photographer).with_preview_image

      if folder_id
        folder = HedonismBotSchema.object_from_id(folder_id, context)
        @photos = folder ? @photos.in_album(folder.id) : @photos.none
      end

      @photos
    end

    def folders(face_id: nil)
      if face_id
        face = HedonismBotSchema.object_from_id(face_id, context)
        face.photos.map(&:album).uniq
      else
        photographer.folders
      end
    end

    def events
      []
    end

    def audience_kit_catalog(from: nil, to: nil, query: nil, latitude: nil, longitude: nil)
      unless context[:service_account] || context[:current_user]&.admin_of?(photographer)
        raise GraphQL::ExecutionError, "Admin sign-in required"
      end

      AudienceKitCatalog.new(photographer).audiences(from: from, to: to, query: query&.truncate(100),
                                                     latitude: latitude, longitude: longitude)
    rescue AudienceKit::Client::Error => e
      raise GraphQL::ExecutionError, e.message
    end

    def venues
      []
    end

    def photos(face_id: nil, folder_id: nil)
      photos = PhotoTake.with_photographer(photographer).with_preview_image

      if face_id
        face = GlobalID.parse(face_id).model_id
        photos = photos.with_face(face)
      end

      if folder_id
        folder = GlobalID.parse(folder_id).model_id
        photos = photos.where(folder_date: folder)
      end

      photos.order(:taken_at)
    end
  end
end
