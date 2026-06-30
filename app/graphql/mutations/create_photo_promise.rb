# frozen_string_literal: true

module Mutations
  class CreatePhotoPromise < BaseMutation
    description "Creates a new upload photo promise"

    field :promise, Types::PhotoPromiseType, null: false

    def resolve
      @promise = PhotoPromise.create(photographer: context[:photographer])

      { promise: @promise }
    end
  end
end
