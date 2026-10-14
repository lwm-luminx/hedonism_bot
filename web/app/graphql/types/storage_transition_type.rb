# frozen_string_literal: true

module Types
  class StorageTransitionType < Types::BaseEnum
    description "A move of an album's originals between storage tiers that is in progress"

    value "ARCHIVING", "Originals are moving to archive storage", value: "archiving"
    value "RESTORING", "Originals are moving back to standard storage", value: "restoring"
  end
end
