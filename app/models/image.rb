# frozen_string_literal: true

class Image < ApplicationRecord
  validates :content_hash, :mime_type, :source_url, :cdn_url, presence: true

  def self.for_url(url)
    return nil unless url

    photo = Image.find_by(source_url: url)

    unless photo
      response = Net::HTTP.get_response(URI(url))
      hash = Digest::SHA1.new.digest response.body
      hash_url_safe = Base64.urlsafe_encode64 hash, padding: false

      photo = Image.find_or_create_by(content_hash: hash) do |p|
        p.mime = response["Content-Type"]
        p.source_url = url
        p.cdn_url = "https://noncesoft.azureedge.net/photos/#{hash_url_safe}"
      end

      photo.store(hash_url_safe, response.body)
    end

    photo
  end

  def store(name, data)
    client = Azure::Storage::Blob::BlobService.create(storage_account_name: AZURE_STORAGE_NAME,
                                                      storage_access_key: Rails.application.secrets[:cdn_storage_key])

    client.create_block_blob("photos", name, data, content_type: mime)
  end
end
