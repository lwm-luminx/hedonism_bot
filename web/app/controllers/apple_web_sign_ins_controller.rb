# frozen_string_literal: true

# Sign in with Apple for the website's admin console. A photographer's host starts sign-in through
# the auth bridge on api.<SERVICE_DOMAIN> (AuthBridgesController); #start sends the browser to Apple
# with the Services ID, and Apple posts the identity token back to AppleWebCallbacksController.
#
# That callback is a cross-site form POST, so the browser leaves out the Lax session cookie. The
# bridge context therefore travels in a signed OAuth state, and the token's nonce claim must be the
# SHA-256 of the one-time nonce kept inside that state.
class AppleWebSignInsController < ApplicationController
  include TenantAuthReturn

  skip_before_action :set_photographer

  AUTHORIZE_URL = "https://appleid.apple.com/auth/authorize"
  STATE_PURPOSE = :apple_web_state

  def start
    context = session[:auth_bridge]
    unless api_host? && context && context["expires_at"].to_i > Time.current.to_i
      return render plain: "Sign-in expired. Go back and try again.", status: :bad_request
    end

    nonce = SecureRandom.urlsafe_base64(32)
    state = verifier.generate({ "auth_bridge" => context, "nonce" => nonce }, purpose: STATE_PURPOSE, expires_in: 10.minutes)
    query = { client_id: AppleIdentityToken.web_client_id, redirect_uri: callback_url, response_type: "code id_token",
              response_mode: "form_post", scope: "email", state: state, nonce: Digest::SHA256.hexdigest(nonce) }
    redirect_to "#{AUTHORIZE_URL}?#{query.to_query}", allow_other_host: true
  end

  private

  def api_host?
    request.host == "api.#{Rails.configuration.x.service_domain}"
  end

  def callback_url
    "https://api.#{Rails.configuration.x.service_domain}/auth/apple/callback"
  end

  def verifier
    Rails.application.message_verifier(STATE_PURPOSE)
  end
end
