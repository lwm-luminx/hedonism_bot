module Mutations
  class AttachPhotoPromiseFiles < BaseMutation
    argument :id, ID, "The ID of the photo promise to attach files to", required: true
    argument :files, [ Types::PhotoPromiseFileInputType ], "The files to include in the photo promise", required: true

    field :promise, Types::PhotoPromiseType, null: false
    field :files, [ Types::PhotoPromiseFileType ], null: false, description: "The files just added, in input order"

    def resolve(id:, files:)
      @promise = HedonismBotSchema.object_from_id(id, context)
      unless @promise.is_a?(PhotoPromise)
        raise GraphQL::ExecutionError, "Photo promise not found"
      end
      added = files.map do |file|
        @promise.photo_promise_files.build file.to_h
      end
      @promise.save!

      { promise: @promise, files: added }
    end
  end
end
