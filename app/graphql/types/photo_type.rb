module Types
  class PhotoType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :name, String, null: false
    field :content_type, String, null: false, description: "MIME type of the photo"
    field :filename, String, null: false, description: "Filename of the photo"
    field :byte_size, Integer
    field :folder, Types::FolderType, null: true, description: "Folder containing the photo"
    field :faces, Types::FaceType.connection_type, null: false, description: "Faces in the photo"
    field :is_purchased, Boolean, null: false, description: "Whether the photo has been purchased"
    field :preview_url, String, null: true, description: "URL to a preview image of the photo"
    field :alternate_description, String, null: false, description: "Description of the photo for the visually impaired"
    field :taken_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Date and time the photo was taken"
    field :facial_recognition_url, String, null: true, description: "URL to a preview image of the photo for facial recognition"

    def facial_recognition_url
      face_image = @object.images.select { |img| img.content_type == "image/jpeg" }.first
      face_image&.url
    end

    def taken_at
      @object.taken_at || @object.created_at
    end

    def filename
      @object.original_filename
    end

    def faces
      @object.photo_people
    end

    def is_purchased
      false
    end

    def alternate_description
      "TODO: Replace me with a for the blind description of the image"
    end

    def preview_url
      @object.preview_url
    end
  end
end