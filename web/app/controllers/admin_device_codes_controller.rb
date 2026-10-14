class AdminDeviceCodesController < ApplicationController
  def create
    return head :unauthorized unless current_user
    return head :forbidden unless current_user.admin_of?(photographer)

    grant, code = ServiceAccount.transaction do
      source = ServiceAccount.active.find_by(photographer: photographer, user: current_user, name: "Device pairing")
      unless source
        source, = ServiceAccount.issue!(photographer: photographer, name: "Device pairing")
        source.update!(user: current_user)
      end
      DeviceLoginGrant.issue!(service_account: source)
    end
    response.headers["Cache-Control"] = "no-store"
    render json: { code: code, expires_at: grant.expires_at, photographer: photographer.name }
  end
end
