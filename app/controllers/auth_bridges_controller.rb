# frozen_string_literal: true

# Host-only cookies cannot cross tenant domains. Bind the return ticket to the browser
# that began sign-in, and keep Facebook's callback on one service-owned hostname.
class AuthBridgesController < ApplicationController
  skip_before_action :set_photographer, only: :new

  def start
    nonce = SecureRandom.hex(32)
    session[:auth_nonce] = nonce
    context = { "photographer_id" => photographer.id, "host" => request.host, "nonce" => nonce, "expires_at" => 5.minutes.from_now.to_i }
    ticket = verifier.generate(context, purpose: :auth_bridge, expires_in: 5.minutes)
    redirect_to "https://api.#{Rails.configuration.x.service_domain}/auth/bridge?#{ { ticket: ticket }.to_query }", allow_other_host: true
  end

  def new
    # Send only the origin, keeping tickets out of referrers while preserving CSRF origin checks.
    response.headers["Referrer-Policy"] = "strict-origin"
    context = verifier.verified(params[:ticket], purpose: :auth_bridge)
    target = context && Photographer.for_host(context["host"])
    unless request.host == "api.#{Rails.configuration.x.service_domain}" && target && target.id == context["photographer_id"]
      return render plain: "Invalid sign-in request", status: :bad_request
    end

    reset_session
    session[:auth_bridge] = context
    render :new
  end

  def complete
    response.headers["Referrer-Policy"] = "strict-origin"
    ticket = verifier.verified(params[:ticket], purpose: :auth_return)
    nonce = session.delete(:auth_nonce)
    unless ticket && nonce && ticket["nonce"] == nonce && ticket["host"] == request.host && ticket["photographer_id"] == photographer.id
      return render plain: "Sign-in expired or invalid", status: :unauthorized
    end

    reset_session
    if ticket["user_id"] && User.exists?(id: ticket["user_id"], deletion_pending_at: nil)
      session[:user_id] = ticket["user_id"]
      redirect_to "/admin"
    else
      redirect_to "/admin?#{ { auth_error: ticket['error'] || 'invalid_user' }.to_query }"
    end
  end

  private

  def verifier
    Rails.application.message_verifier(:tenant_auth)
  end
end
