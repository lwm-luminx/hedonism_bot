# frozen_string_literal: true

# Associates api.<domain> with Chip, Chip for Mac and Cogsworth (webcredentials), so Apple's
# password and passkey AutoFill treat the web and the apps as one set of credentials.
# marketing/.well-known/apple-app-site-association serves the same file for the apex domain.
class AppleAppSiteAssociationsController < ActionController::API
  APP_IDS = %w[host.lumiere.Chip host.lumiere.ChipMac host.lumiere.Cogsworth].map { |id| "DWVXMLB45Y.#{id}" }.freeze

  def show
    expires_in 1.hour, public: true
    render json: { webcredentials: { apps: APP_IDS } }
  end
end
