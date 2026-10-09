module Types
  class FolderType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :name, String, null: false
    field :upload_context, GraphQL::Types::JSON, null: false, description: "Event and venue supplied at upload"

    field :faces, Types::FaceType.connection_type, null: false, description: "Faces in the folder"
    field :photos, Types::PhotoType.connection_type, null: false, description: "Photos in the folder"
    field :photo_count, Integer, null: false, description: "Total number of photos in the folder"

    def photo_count
      @object.photos.count
    end

    def name
      @object.name
    end
  end
end
