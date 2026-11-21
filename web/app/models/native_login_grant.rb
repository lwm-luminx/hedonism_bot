# A one-time, PKCE-bound code from a native browser sign-in (NativeAccountsController). Grants made
# without an archive let the person pick one after sign-in (ArchiveChoice).
class NativeLoginGrant < ApplicationRecord
  CLIENT_NAME = "Lumière mobile".freeze

  belongs_to :user
  belongs_to :photographer, optional: true

  # Redeems the code with its PKCE verifier. Returns the sign-in JSON (see ArchiveChoice.response_for),
  # or nil when the code, proof or the person's access is not valid.
  def self.exchange(code:, verifier:)
    grant = find_by(code_digest: Digest::SHA256.hexdigest(code.to_s))
    return unless grant

    grant.with_lock do
      proof = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier.to_s), padding: false)
      return unless grant.expires_at.future? && ActiveSupport::SecurityUtils.secure_compare(proof, grant.challenge)
      return if grant.user.deletion_pending_at

      body = grant.sign_in_response
      grant.destroy! if body
      body
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def sign_in_response
    return ArchiveChoice.response_for(user, client_name: CLIENT_NAME) unless photographer
    return unless user.admin_of?(photographer)

    ArchiveChoice.issue(user, photographer, client_name: CLIENT_NAME)
  end
end
