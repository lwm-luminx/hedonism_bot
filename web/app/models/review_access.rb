# frozen_string_literal: true

# A fixed, reusable device code for App Review and the apps' UI tests. Ordinary device codes expire
# after ten minutes and work once, which a reviewer can't use. This code only ever signs in to the
# review photographer (REVIEW_PHOTOGRAPHER, default "review"), never a real archive, and is off
# unless REVIEW_DEVICE_CODE is set. `bin/rails review:setup` creates both.
module ReviewAccess
  DEFAULT_SUBDOMAIN = "review"

  def self.subdomain
    ENV.fetch("REVIEW_PHOTOGRAPHER", DEFAULT_SUBDOMAIN)
  end

  def self.code
    normalize(ENV.fetch("REVIEW_DEVICE_CODE", nil)).presence
  end

  # Returns [account, token] for the review photographer when `given` is the review code.
  def self.exchange(given)
    expected = code
    return unless expected && expected.length >= 16
    return unless ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(normalize(given)),
                                                              Digest::SHA256.hexdigest(expected))

    photographer = Photographer.find_by(subdomain: subdomain)
    return unless photographer

    ServiceAccount.issue!(photographer: photographer, name: "App Review device")
  end

  def self.normalize(value)
    value.to_s.delete("- ").upcase
  end
  private_class_method :normalize
end
