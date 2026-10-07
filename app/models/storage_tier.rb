# Photo originals live in one of two Active Storage services: the hot service (Bucketeer on Heroku,
# priced by flat plan tier) or an optional archive service, any S3-compatible bucket billed per GB
# (AWS S3 with a cold storage class, Backblaze B2, Cloudflare R2). Previews always stay hot.
module StorageTier
  ORIGINAL_ATTACHMENTS = %w[raw_image images].freeze
  PREVIEW_CONTENT_TYPE = "image/jpeg"

  def self.hot_service_name
    ActiveStorage::Blob.service.name.to_s
  end

  def self.archive_service_name
    Rails.configuration.x.archive_storage_service&.to_s
  end

  def self.archive_available?
    archive_service_name.present?
  end

  # Blobs of the original files (RAW and camera HEIF/JPEG) of the given photo takes.
  def self.original_blobs(photo_takes)
    ActiveStorage::Blob
      .joins(:attachments)
      .where(active_storage_attachments: { record_type: "PhotoTake", record_id: photo_takes.select(:id), name: ORIGINAL_ATTACHMENTS })
      .where("active_storage_attachments.name = 'raw_image' OR active_storage_blobs.content_type IS DISTINCT FROM ?", PREVIEW_CONTENT_TYPE)
      .distinct
  end

  # Copies the blob's bytes to the named service, repoints the blob, then deletes the old copy.
  # Readers keep working throughout because they resolve the service from blob.service_name.
  def self.move(blob, to:)
    to = to.to_s
    return if blob.service_name == to

    source = blob.service
    target = ActiveStorage::Blob.services.fetch(to)

    blob.open do |file|
      target.upload(blob.key, file, checksum: blob.checksum, content_type: blob.content_type)
    end
    blob.update!(service_name: to)
    source.delete(blob.key)
  end
end
