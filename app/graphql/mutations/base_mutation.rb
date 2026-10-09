# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    object_class Types::BaseObject

    # Uploading is for the photographer's admins (signed in) and their service accounts (the Mac uploader).
    def require_uploader!
      return if context[:service_account]
      return if context[:current_user]&.admin_of?(context[:photographer])

      raise GraphQL::ExecutionError, "Admin sign-in required"
    end
  end
end
