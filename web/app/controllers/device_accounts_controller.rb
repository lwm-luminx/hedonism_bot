class DeviceAccountsController < ApplicationController
  skip_before_action :set_photographer
  skip_forgery_protection

  def create
    source = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return head :unauthorized unless source

    grant, code = DeviceLoginGrant.issue!(service_account: source)
    response.headers["Cache-Control"] = "no-store"
    render json: { code: code, expires_at: grant.expires_at }
  end

  def exchange
    pair = DeviceLoginGrant.exchange(code: params[:code])
    return render json: { error: "This code is invalid or expired. Ask for a new device code." }, status: :unauthorized unless pair

    account, token = pair
    response.headers["Cache-Control"] = "no-store"
    render json: { token: token, subdomain: account.photographer.subdomain, name: account.photographer.name }
  end
end
