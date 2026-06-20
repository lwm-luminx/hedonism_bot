class PhotoPromiseFile < ApplicationRecord
  belongs_to :photo_promise
  has_one_attached :file

  before_create do
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: self.original_filename,
      byte_size: self.file_size_bytes,
      checksum: self.image_hash,
      content_type: self.content_type
    )
    self.upload_url = blob.service_url_for_direct_upload
  end
end
