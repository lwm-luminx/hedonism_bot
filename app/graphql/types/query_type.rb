# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :photographer, Types::PhotographerType, null: false, description: "The current Photographer for the request"
    field :photos, [ Types::PhotoType ], null: false, description: "All photos for a particular Photographer" do
      argument :face_id, ID, required: false, description: "Filter photos by face ID"
      argument :folder_id, ID, required: false, description: "Filter photos by folder ID"
    end
    field :faces, Types::FaceType.connection_type, null: false, description: "All faces for a particular Photographer" do
      argument :folder_id, ID, required: false, description: "Filter faces by folder ID"
    end
    field :folders, Types::FolderType.connection_type, null: false, description: "All groupings for a particular Photographer" do
      argument :face_id, ID, required: false, description: "Filter folders by face ID"
    end

    def photographer
      context[:photographer]
    end

    def faces(folder_id: nil)
      if folder_id
        photos = Photo.where("folder_date = ?", GlobalID.parse(folder_id).model_id)
        photos.map { |photo| photo.people }.flatten.uniq
      else
        PhotoPerson.joins(:face_image_blob).includes(:person).map { |photo_person| photo_person.person }.uniq
      end
    end

    def folders(face_id: nil)
      if face_id
        face = HedonismBotSchema.object_from_id(face_id, context)
        photos = face.photos.group_by(&:folder_date)
        photos.map { |folder, photos| Folder.new(folder, photos) }
      else
        photographer.folders
      end
    end

    def photos(face_id: nil, folder_id: nil)
      photos = Photo.where(photographer: photographer).with_preview_image

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
