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
      self.tenant.people
    end

    field :folders, Types::FolderType.connection_type, null: false, description: "All groupings for a particular tenant"
    def folders
      self.tenant.folders
    end

    field :photos, [Types::PhotoType], null: false, description: "All photos for a particular tenant"
    def photos
      self.tenant.photos
    end

    field :photo, PhotoType do
      argument :id, ID, required: true, description: "ID of the photo"
    end
    def photo(id:)
      Photo.find(id)
    end
  end
end
