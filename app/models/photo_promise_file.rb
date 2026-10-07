class PhotoPromiseFile < ApplicationRecord
  RAW_CONTENT_TYPES = PhotoTake::RAW_FORMATS.values.pluck(:mime_type).freeze

  belongs_to :photo_promise
  belongs_to :photo_take, optional: true
  has_one_attached :file

  # Base64 MD5 of the file. Storage services verify uploads against it (S3 checks Content-MD5),
  # so uploaders should send it; image_hash (SHA-256) is used when it is missing.
  attribute :checksum, :string

  before_create do
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: self.original_filename,
      byte_size: self.file_size_bytes,
      checksum: checksum.presence || Base64.strict_encode64(self.image_hash),
      content_type: self.content_type
    )
    self.blob_id = blob.id
    self.upload_url = blob.service_url_for_direct_upload
  end

  def blob
    ActiveStorage::Blob.find_by(id: blob_id)
  end

  # Headers the PUT to upload_url must carry (they are part of the signature).
  def upload_headers
    blob&.service_headers_for_direct_upload || {}
  end

  def uploaded?
    blob.present? && blob.service.exist?(blob.key)
  end

  def raw?
    RAW_CONTENT_TYPES.include?(content_type)
  end

  def basename
    File.basename(original_filename, ".*").downcase
  end

  def take_attributes
    { original_filename: original_filename, content_type: content_type, file_size_bytes: file_size_bytes, image_hash: image_hash }
  end
end
