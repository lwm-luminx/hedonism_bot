# frozen_string_literal: true

module Mutations
  class RestoreAlbum < ArchiveAlbum
    description "Moves an album's archived photo originals back to standard storage"

    TRANSITION = "restoring"
    DIRECTION = "restore"
  end
end
