class DeviceLoginGrant < ApplicationRecord
  belongs_to :service_account

  def self.issue!(service_account:)
    code = SecureRandom.hex(10).upcase
    grant = create!(service_account: service_account, code_digest: digest(code), expires_at: 10.minutes.from_now)
    [ grant, code.scan(/.{4}/).join("-") ]
  end

  def self.digest(code)
    Digest::SHA256.hexdigest(code.to_s.delete("- ").upcase)
  end

  def self.exchange(code:)
    return unless code.to_s.delete("- ").match?(/\A[0-9a-fA-F]{20}\z/)

    grant = find_by(code_digest: digest(code))
    return unless grant

    grant.with_lock do
      source = grant.service_account
      return unless grant.expires_at.future? && !source.revoked_at
      return if source.user_id && (!source.user || source.user.deletion_pending_at || !source.user.admin_of?(source.photographer))

      account, token = ServiceAccount.issue!(photographer: source.photographer, name: "Chip device")
      account.update!(user: source.user)
      grant.destroy!
      [ account, token ]
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
