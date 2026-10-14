class NativeLoginGrant < ApplicationRecord
  belongs_to :user
  belongs_to :photographer

  def self.exchange(code:, verifier:)
    grant = find_by(code_digest: Digest::SHA256.hexdigest(code.to_s))
    return unless grant

    grant.with_lock do
      proof = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier.to_s), padding: false)
      return unless grant.expires_at.future? && ActiveSupport::SecurityUtils.secure_compare(proof, grant.challenge)
      return if grant.user.deletion_pending_at || !grant.user.admin_of?(grant.photographer)

      account, token = ServiceAccount.issue!(photographer: grant.photographer, name: "Lumière mobile")
      account.update!(user: grant.user)
      grant.destroy!
      [ account, token ]
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
