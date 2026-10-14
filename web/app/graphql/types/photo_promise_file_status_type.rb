# frozen_string_literal: true

module Types
  class PhotoPromiseFileStatusType < Types::BaseEnum
    description "Photo promise file state enum"

    value "PENDING", "Pending", value: "pending"
    value "SUCCESS", "Success", value: "success"
    value "FAILED", "Failed", value: "failed"
  end
end
