# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :tenant, Types::TenantType, null: false, description: "The current tenant for the request"
    def tenant
      Tenant.default_tenant
    end

    field :faces, Types::FaceType.connection_type, null: false, description: "All faces for a particular tenant"
    def faces
      tenant.people
    end

    field :folders, Types::FolderType.connection_type, null: false, description: "All groupings for a particular tenant"
    def folders
      tenant.folders
    end

    field :photos, [ Types::PhotoType ], null: false, description: "All photos for a particular tenant" do
      argument :face_id, ID, required: false, description: "Filter photos by face ID"
      argument :folder_id, ID, required: false, description: "Filter photos by folder ID"
    end
    def photos(face_id: nil, folder_id: nil)
      if face_id
        photos = HedonismBotSchema.object_from_id(face_id, context).photos
      else
        photos = tenant.photos.order(:folder_date)
      end

      photos = photos.where(folder_date: folder_id) if folder_id

      photos
    end

    field :photo, PhotoType, null: true do
      argument :id, ID, required: true, description: "ID of the photo"
    end
    def photo(id:)
      Photo.find(id)
    end
  end
end
