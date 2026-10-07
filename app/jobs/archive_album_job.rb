# Moves an album's photo originals to the archive service ("archive") or back to the hot service
# ("restore"). Previews stay hot so galleries keep loading. Safe to retry: moved blobs are skipped.
class ArchiveAlbumJob < ApplicationJob
  queue_as :default

  DIRECTIONS = %w[archive restore].freeze

  def perform(album, direction)
    raise ArgumentError, "unknown direction #{direction}" unless DIRECTIONS.include?(direction)

    target = direction == "archive" ? StorageTier.archive_service_name : StorageTier.hot_service_name
    raise "No archive storage is configured" if target.blank?

    StorageTier.original_blobs(album.photo_takes).find_each do |blob|
      StorageTier.move(blob, to: target)
    end
  ensure
    album.update_columns(storage_transition: nil) if album&.persisted?
  end
end
