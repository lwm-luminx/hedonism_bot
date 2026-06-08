# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :tenant, Types::TenantType, null: false, description: "The current tenant for the request"
    field :photos, [ Types::PhotoType ], null: false, description: "All photos for a particular tenant" do
      argument :face_id, ID, required: false, description: "Filter photos by face ID"
      argument :folder_id, ID, required: false, description: "Filter photos by folder ID"
    end
    field :faces, Types::FaceType.connection_type, null: false, description: "All faces for a particular tenant" do
      argument :folder_id, ID, required: false, description: "Filter faces by folder ID"
    end
    field :folders, Types::FolderType.connection_type, null: false, description: "All groupings for a particular tenant" do
      argument :face_id, ID, required: false, description: "Filter folders by face ID"
    end

    def tenant
      Tenant.default_tenant
    end

    def faces(folder_id: nil)
      if folder_id
        folder = Folder.new(folder_id, Photo.where("folder_date = ?", folder_id).all)
        folder.photos.map { |photo| photo.people }.flatten.uniq
      else
        tenant.people
      end
    end

    def folders(face_id: nil)
      if face_id
        face = HedonismBotSchema.object_from_id(face_id, context)
        photos = face.photos.group_by(&:folder_date)
        photos.map { |folder, photos| Folder.new(folder, photos) }
      else
        tenant.folders
      end
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
