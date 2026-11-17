# frozen_string_literal: true

# Sign in with Apple for the website's admin console. A photographer's host starts sign-in through
# the auth bridge on api.<SERVICE_DOMAIN> (AuthBridgesController); #start sends the browser to Apple
# with the Services ID, and Apple posts the identity token back to #callback.
#
# Apple's callback is a cross-site form POST, so the browser leaves out the Lax session cookie. The
# bridge context therefore travels in a signed OAuth state, and the token's nonce claim must be the
# SHA-256 of the one-time nonce kept inside that state. The ticket #callback returns can only be
# redeemed by the browser holding the tenant host's own sign-in nonce, as with Facebook.
#
# Like the apps, this never creates accounts: the Apple ID must already belong to an admin, linked
# from Chip or Cogsworth or matched by an Apple-verified email (User.from_apple).
class AppleWebSignInsController < ApplicationController
  include TenantAuthReturn

  skip_before_action :set_photographer
  # Apple's form_post carries no CSRF token; the signed state and the token's nonce stand in for it.
  skip_forgery_protection only: :callback

  AUTHORIZE_URL = "https://appleid.apple.com/auth/authorize"
  STATE_PURPOSE = :apple_web_state
  NOT_LINKED = "This Apple ID isn't linked to a Lumière admin yet. Sign in with Facebook once, then choose " \
               "Link Apple ID in Chip or Cogsworth."
  NOT_VERIFIED = "Sign in with Apple could not be verified. Try again."

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

  def callback
    payload = verifier.verified(params[:state].to_s, purpose: STATE_PURPOSE) if api_host?
    context = payload["auth_bridge"] if payload.is_a?(Hash)
    return render plain: "Sign-in expired or invalid", status: :bad_request unless context.is_a?(Hash)

    # Apple reports a cancelled sheet as error=user_cancelled_authorize.
    return redirect_to_tenant(context, error: "Sign in with Apple was cancelled.") if params[:error].present?

    claims = AppleIdentityToken.verify(params[:id_token], nonce: payload["nonce"], audience: [ AppleIdentityToken.web_client_id ])
    user = User.from_apple(claims)
    user ? redirect_to_tenant(context, user_id: user.id) : redirect_to_tenant(context, error: NOT_LINKED)
  rescue AppleIdentityToken::Invalid
    redirect_to_tenant(context, error: NOT_VERIFIED)
  end

  private

  def api_host?
    request.host == "api.#{Rails.configuration.x.service_domain}"
  end

  def callback_url
    "https://api.#{Rails.configuration.x.service_domain}/auth/apple/callback"
  end

  def verifier
    Rails.application.message_verifier(:apple_web_state)
  end
end
