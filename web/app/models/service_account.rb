# A long-lived API token that acts as a photographer, for unattended clients like the Mac SD card
# uploader. Create one with `bin/rails service_accounts:create SUBDOMAIN=… NAME=…`; the token is
# shown once and only its SHA-256 digest is stored.
class ServiceAccount < ApplicationRecord
  TOKEN_PREFIX = "hbsa_"

  belongs_to :photographer
  belongs_to :user, optional: true

  validates :name, :token_digest, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  # Returns [account, token].
  def self.issue!(photographer:, name:)
    token = "#{TOKEN_PREFIX}#{SecureRandom.base58(40)}"
    [ create!(photographer: photographer, name: name, token_digest: digest(token)), token ]
  end

  def self.authenticate(token)
    return if token.blank? || !token.start_with?(TOKEN_PREFIX)

    account = active.find_by(token_digest: digest(token))
    return if account&.user_id && (!account.user || account.user.deletion_pending_at || !account.user.admin_of?(account.photographer))

    account&.touch(:last_used_at)
    account
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
