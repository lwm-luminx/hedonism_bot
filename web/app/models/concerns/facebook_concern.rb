# frozen_string_literal: true

require "koala"

module FacebookConcern
  def self.oauth
    app_id = ::Rails.application.secrets[:facebook_app_id]
    app_secret = ::Rails.application.secrets[:facebook_secret]

    ::Koala::Facebook::OAuth.new app_id, app_secret
  end
end
