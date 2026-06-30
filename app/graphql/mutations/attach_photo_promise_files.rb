module Mutations
  class AttachPhotoPromiseFiles < BaseMutation
    argument :id, ID, "The ID of the photo promise to attach files to", required: true
    argument :files, [ Types::PhotoPromiseFileInputType ], "The files to include in the photo promise", required: true

    field :promise, Types::PhotoPromiseType, null: false

    def resolve(id:, files:)
      @promise = GlobalID::Locator.locate(id)
      files.each do |file|
        @promise.photo_promise_files.build file.to_h
      end
      @promise.save!

      { promise: @promise }
    end
  end
end
