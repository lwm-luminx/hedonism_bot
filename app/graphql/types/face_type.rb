module Types
  class FaceType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :photos, Types::PhotoType.connection_type, null: false
    field :photo_count, Integer, null: false
    field :thumbnail_url, String, null: true

    def thumbnail_url
      @object.photo_facess.first&.face_image&.url
    end
  end
end
