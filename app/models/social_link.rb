# frozen_string_literal: true

class SocialLink < ApplicationRecord
  has_many :tracks, dependent: :nullify

  def url
    case provider
    when "soundcloud"
      "https://soundcloud.com/#{handle}"
    when "facebook"
      "https://facebook.com/#{handle}"
    when "twitter"
      "https://twitter.com/#{handle}"
    when "instagram"
      "https://instagram.com/#{handle}"
    end
  end
end
