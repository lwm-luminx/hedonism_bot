# frozen_string_literal: true

require "net/http"

# Verifies a Sign in with Apple identity token sent by Chip or Cogsworth. Apple signs the token
# with one of the keys published at appleid.apple.com/auth/keys; its audience is the app's bundle
# ID and its nonce claim is the SHA-256 of the one-time nonce the app generated for the request.
class AppleIdentityToken
  class Invalid < StandardError; end

  ISSUER = "https://appleid.apple.com"
  KEYS_URL = URI("https://appleid.apple.com/auth/keys")
  KEYS_CACHE_KEY = "apple_sign_in/jwks"
  DEFAULT_CLIENT_IDS = %w[host.lumiere.Chip host.lumiere.ChipMac host.lumiere.Cogsworth].freeze

  Claims = Data.define(:sub, :email, :email_verified, :private_email) do
    # An email Apple verified and that reaches the person directly, not a private relay address.
    def matchable_email
      email.presence if email_verified && !private_email
    end
  end

  def self.client_ids
    ENV.fetch("APPLE_SIGN_IN_CLIENT_IDS", nil)&.split(",")&.map(&:strip)&.compact_blank.presence || DEFAULT_CLIENT_IDS
  end

  def self.verify(token, nonce:)
    raise Invalid, "Missing identity token" if token.blank? || nonce.blank?

    payload, = JWT.decode(token.to_s, nil, true,
                          algorithms: [ "RS256" ], jwks: method(:load_keys),
                          iss: ISSUER, verify_iss: true, aud: client_ids, verify_aud: true,
                          verify_iat: true, required_claims: %w[sub exp iat nonce])
    expected = Digest::SHA256.hexdigest(nonce.to_s)
    raise Invalid, "Nonce mismatch" unless ActiveSupport::SecurityUtils.secure_compare(payload["nonce"].to_s, expected)

    Claims.new(sub: payload.fetch("sub"), email: payload["email"].to_s.downcase.presence,
               email_verified: truthy?(payload["email_verified"]), private_email: truthy?(payload["is_private_email"]))
  rescue JWT::DecodeError, KeyError => e
    raise Invalid, e.message
  end

  # JWT's jwks loader: Apple rotates keys, so an unknown key ID refetches the set (at most once a minute).
  def self.load_keys(options)
    if options[:kid_not_found] && Rails.cache.write("#{KEYS_CACHE_KEY}/refetch", true, expires_in: 1.minute, unless_exist: true)
      Rails.cache.delete(KEYS_CACHE_KEY)
    end
    Rails.cache.fetch(KEYS_CACHE_KEY, expires_in: 12.hours) { fetch_keys }
  end

  def self.fetch_keys
    response = Net::HTTP.get_response(KEYS_URL)
    raise Invalid, "Could not fetch Apple's signing keys (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).deep_symbolize_keys
  end

  def self.truthy?(value)
    value == true || value.to_s == "true"
  end
  private_class_method :fetch_keys, :truthy?
end
