module Mutations
  class DeleteAlbum < BaseMutation
    description "Deletes a gallery album and its photos"

    argument :id, ID, required: true
    field :deleted_id, ID, null: false

    def ready?(**args)
      raise GraphQL::ExecutionError, "Admin sign-in required" unless context[:current_user]&.admin_of?(context[:photographer])

      super
    end

    def resolve(id:)
      album = HedonismBotSchema.object_from_id(id, context)
      raise GraphQL::ExecutionError, "Album not found" unless album.is_a?(Album)

      Album.transaction do
        album.photos.each do |photo|
          photo.photo_takes.each(&:destroy!)
          photo.destroy!
        end
        PhotoPromise.where(album: album).update_all(album_id: nil)
        album.destroy!
      end

      { deleted_id: id }
    end
  end
end
