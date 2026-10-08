require "base64"
require "openssl"
require "json"

module Facebook
  class SignedRequestVerifier
    class InvalidRequest < StandardError; end
    class ConfigurationError < StandardError; end
    MAX_BYTES = 16_384

    def self.call(value, secret: FACEBOOK_APP_SECRET, app_id: FACEBOOK_APP_ID)
      raise ConfigurationError if secret.nil? || app_id.nil? || secret.blank? || app_id.blank?
      raise InvalidRequest unless value.is_a?(String) && value.bytesize <= MAX_BYTES
      parts = value.split(".", -1)
      raise InvalidRequest unless parts.size == 2
      signature = parts.fetch(0)
      encoded = parts.fetch(1)
      signature = decode(signature)
      expected = OpenSSL::HMAC.digest("SHA256", secret, encoded)
      raise InvalidRequest unless signature.bytesize == 32 && ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      payload = JSON.parse(decode(encoded))
      raise InvalidRequest unless payload.is_a?(Hash)
      raise InvalidRequest unless payload["algorithm"].is_a?(String) && payload["algorithm"].upcase == "HMAC-SHA256"
      raise InvalidRequest unless payload["user_id"].is_a?(String) && payload["user_id"].match?(/\A[0-9]{1,128}\z/)
      raise InvalidRequest if payload.key?("app_id") && payload["app_id"].to_s != app_id.to_s
      raise InvalidRequest if payload.key?("issued_at") && !(payload["issued_at"].is_a?(Integer) && payload["issued_at"] >= 0)
      payload
    rescue ArgumentError, JSON::ParserError
      raise InvalidRequest
    end

    def self.decode(segment)
      raise InvalidRequest unless segment.match?(/\A[A-Za-z0-9_-]+={0,2}\z/)
      unpadded = segment.delete_suffix("==").delete_suffix("=")
      padding = "=" * ((4 - unpadded.length % 4) % 4)
      raise InvalidRequest if segment.include?("=") && segment != unpadded + padding
      decoded = Base64.strict_decode64((unpadded + padding).tr("-_", "+/"))
      raise InvalidRequest unless Base64.urlsafe_encode64(decoded, padding: false) == unpadded
      decoded
    end
    private_class_method :decode
  end
end
