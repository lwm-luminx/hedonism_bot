# frozen_string_literal: true

module Types
  class PhotoPromiseFileInputType < Types::BaseInputObject
    argument :original_filename, String, required: true
    argument :content_type, String, required: true
    argument :file_size_bytes, Integer, required: true
    argument :image_hash, BinaryType, required: true
    argument :checksum, String, required: false, description: "Base64 MD5 of the file, verified by storage on upload"
  end
end
