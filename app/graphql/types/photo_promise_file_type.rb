# frozen_string_literal: true

module Types
  class PhotoPromiseFileType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :content_type, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :file_size_bytes, Integer
    field :image_hash, Types::BinaryType
    field :original_filename, String, null: false
    field :status, Types::PhotoPromiseFileStatusType, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :upload_url, String, null: false
    field :upload_headers, GraphQL::Types::JSON, null: false, description: "Headers to send with the PUT to uploadUrl"
    field :photo, Types::PhotoType, null: true, method: :photo_take, description: "The photo take this file became once uploaded"
  end
end
