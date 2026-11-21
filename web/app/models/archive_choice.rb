# frozen_string_literal: true

# Chip and Cogsworth sign people in without first asking which archive (photographer) to use. Once
# Facebook or Apple has identified the person, they get a credential straight away when they
# administer exactly one archive. Otherwise they get the list of their archives and a short-lived
# signed selection, and the app picks one with POST /auth/archives/select.
class ArchiveChoice
  PURPOSE = :archive_choice
  EXPIRES_IN = 10.minutes
  NO_ARCHIVES = "This account doesn't administer a Lumière archive yet. Ask an archive's admin to add you."

  # The archives this person can sign in to, by name. A god-mode admin can sign in to every archive.
  def self.archives_for(user)
    scope = user.admin? ? Photographer.all : Photographer.where(id: user.photographer_admins.select(:photographer_id))
    scope.order(:name).to_a
  end

  # The JSON a native sign-in returns: { token:, subdomain:, name: } for a single archive, or
  # { selection:, photographers: [{ subdomain:, name: }] } to choose from. Nil when there is none.
  def self.response_for(user, client_name:)
    archives = archives_for(user)
    return if archives.empty?
    return issue(user, archives.first, client_name: client_name) if archives.one?

    selection = verifier.generate({ "user_id" => user.id, "client" => client_name }, purpose: PURPOSE, expires_in: EXPIRES_IN)
    { selection: selection, photographers: archives.map { |archive| { subdomain: archive.subdomain, name: archive.name } } }
  end

  # Issues the credential for the archive picked from a selection. Nil when the selection is invalid
  # or expired, or the person no longer administers that archive.
  def self.select(selection, subdomain)
    payload = verifier.verified(selection.to_s, purpose: PURPOSE)
    return unless payload.is_a?(Hash)

    user = User.find_by(id: payload["user_id"], deletion_pending_at: nil)
    target = Photographer.find_by(subdomain: subdomain.to_s.strip.downcase)
    issue(user, target, client_name: payload["client"].presence || "Lumière app") if user&.admin_of?(target) && target
  end

  def self.issue(user, photographer, client_name:)
    account, token = ServiceAccount.issue!(photographer: photographer, name: client_name)
    account.update!(user: user)
    { token: token, subdomain: photographer.subdomain, name: photographer.name }
  end

  def self.verifier
    Rails.application.message_verifier(PURPOSE)
  end
  private_class_method :verifier
end
