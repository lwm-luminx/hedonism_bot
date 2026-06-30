# frozen_string_literal: true

class Image < ApplicationRecord
  has_one_attached :image_file
  validates :content_hash, :mime_type, :source_url, :cdn_url, presence: true

  def self.for_url(url)
    photo = Image.find_by(source_url: url)

    unless photo
      response = Net::HTTP.get_response(URI(url))
      hash = Digest::SHA1.new.digest response.body
      hash_url_safe = Base64.urlsafe_encode64 hash, padding: false

      photo = Image.find_or_create_by(content_hash: hash) do |p|
        mime_type = response["Content-Type"]
        raise "Response lacks a mime type" unless mime_type
        p.mime_type = mime_type
        p.source_url = url
        p.cdn_url = "https://noncesoft.azureedge.net/photos/#{hash_url_safe}"
      end

      response.read_body do |body|
        photo.store(hash_url_safe, body)
      end
    end

    photo
  end

  def store(name, data)
    self.image_file.attach(io: StringIO.new(data), filename: name, content_type: mime_type)
  end
end
