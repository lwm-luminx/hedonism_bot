# frozen_string_literal: true

module Mutations
  class UpdatePhotoPromiseFileUpdate < BaseMutation
    description "Updates a update_photo_promise_file by id. SUCCESS turns the uploaded file into a photo take."

    field :file, Types::PhotoPromiseFileType, null: false

    argument :id, ID, required: true
    argument :status, Types::PhotoPromiseFileStatusType, required: true

    def resolve(id:, status:)
      file = GlobalID::Locator.locate(id)
      unless file.is_a?(PhotoPromiseFile) && file.photo_promise.photographer_id == context[:photographer]&.id
        raise GraphQL::ExecutionError, "Upload not found"
      end

      if status == "success"
        raise GraphQL::ExecutionError, "#{file.original_filename} has not been uploaded" unless file.uploaded?

        file.photo_promise.ingest(file)
      end
      file.update!(status: status)

      { file: file }
    end
  end
end
