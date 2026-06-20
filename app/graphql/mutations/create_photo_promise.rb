# frozen_string_literal: true

module Mutations
  class CreatePhotoPromise < BaseMutation
    description "Creates a new upload photo promise"

    field :promise, Types::PhotoPromiseType, null: false

    argument :files, [ Types::PhotoPromiseFileInputType ], required: true

    def resolve(input_files:)
      create_photo_promise_mutation = ::CreatePhotoPromiseMutation.new(**create_photo_promise_mutation_input)
      raise GraphQL::ExecutionError.new "Error creating create_photo_promise_mutation", extensions: create_photo_promise_mutation.errors.to_hash unless create_photo_promise_mutation.save

      { create_photo_promise_mutation: create_photo_promise_mutation }
    end
  end
end
