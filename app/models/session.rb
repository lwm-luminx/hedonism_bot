# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :device
  belongs_to :user

  def initialize(*args)
    super

    self.token_key = SecureRandom.uuid
    self.session_token = SecureRandom.base64
  end

  def to_jwt(request)
    # produce new JWT token
    payload = {
      id: user.id,
      fb_id: user.facebook_id.to_i,
      iat: DateTime.now.to_time.to_i,
      nbf: (DateTime.now - 5.minutes).to_time.to_i,
      # exp: for now calculate exp and return not-authorized if refresh required
      # (exp should never be respected but is a hint)
      iss: request.host_with_port,
      aud: request.host_with_port,
      jti: token_key,
      role: user.admin? ? "admin" : "user"
    }

    JWT.encode payload, Rails.application.secrets[:secret_key_base], "HS256"
  end
end
