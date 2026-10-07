# Bytes stored for a photographer's photos, split by album and by storage tier.
class StorageUsage
  AlbumUsage = Struct.new(:album, :photo_count, :bytes, :original_bytes, :archived_bytes, keyword_init: true) do
    delegate :id, :name, :storage_transition, to: :album

    def hot_bytes = bytes - archived_bytes
  end

  attr_reader :photographer

  def initialize(photographer)
    @photographer = photographer
  end

  def albums
    @albums ||= begin
      totals = Hash.new { |h, k| h[k] = { bytes: 0, original_bytes: 0, archived_bytes: 0 } }
      archive = StorageTier.archive_service_name

      rows.each do |album_id, service_name, original, bytes|
        total = totals[album_id]
        total[:bytes] += bytes
        total[:original_bytes] += bytes if original
        total[:archived_bytes] += bytes if archive && service_name == archive
      end

      photo_counts = PhotoTake.joins(:photo).where(photos: { album_id: album_scope.select(:id) }).group("photos.album_id").count

      album_scope.order(:name).map do |album|
        AlbumUsage.new(album: album, photo_count: photo_counts.fetch(album.id, 0), **totals[album.id])
      end
    end
  end

  def total_bytes = albums.sum(&:bytes)
  def archived_bytes = albums.sum(&:archived_bytes)
  def hot_bytes = total_bytes - archived_bytes
  def archive_available? = StorageTier.archive_available?

  private

  def album_scope
    photographer.albums
  end

  # [album_id, service_name, original?, bytes] for every photo take attachment of the photographer.
  def rows
    original = ActiveRecord::Base.sanitize_sql_array(
      [ "(active_storage_attachments.name = 'raw_image' OR active_storage_blobs.content_type IS DISTINCT FROM ?)", StorageTier::PREVIEW_CONTENT_TYPE ]
    )

    ActiveStorage::Attachment
      .where(record_type: "PhotoTake")
      .joins(:blob)
      .joins("JOIN photo_takes ON photo_takes.id = active_storage_attachments.record_id")
      .joins("JOIN photos ON photos.id = photo_takes.photo_id")
      .where(photos: { album_id: album_scope.select(:id) })
      .group("photos.album_id", "active_storage_blobs.service_name", Arel.sql(original))
      .sum("active_storage_blobs.byte_size")
      .map { |(album_id, service_name, is_original), bytes| [ album_id, service_name, is_original, bytes ] }
  end
end
