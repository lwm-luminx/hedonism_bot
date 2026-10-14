# frozen_string_literal: true

module Mutations
  class DeletePhotos < BaseMutation
    description "Deletes photos and their stored files"

    argument :ids, [ ID ], "The IDs of the photos to delete", required: true

    field :deleted_ids, [ ID ], null: false, description: "The IDs that were deleted"

    def ready?(**args)
      raise GraphQL::ExecutionError, "Admin sign-in required" unless context[:current_user]&.admin_of?(context[:photographer])

      super
    end

    def resolve(ids:)
      takes = ids.map { |id| HedonismBotSchema.object_from_id(id, context) }
      raise GraphQL::ExecutionError, "Photo not found" unless takes.all?(PhotoTake)

      PhotoTake.transaction do
        takes.each do |take|
          photo = take.photo
          take.destroy!
          photo.destroy! if photo && photo.photo_takes.none?
        end
      end

      { deleted_ids: ids }
    end
  end
end
