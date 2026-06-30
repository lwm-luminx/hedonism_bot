# frozen_string_literal: true

module Mutations
  class UpdatePhotoPromiseFileUpdate < BaseMutation
    description "Updates a update_photo_promise_file by id"

    field :file, Types::PhotoPromiseFileType, null: false

    argument :id, ID, required: true
    argument :status, Types::PhotoPromiseFileStatusType, required: true

    def resolve(id:, status:)
      file = GlobalID::Locator.fetch id
      file.update status: status
      file.save!

      { file: file }
    end
  end
end
