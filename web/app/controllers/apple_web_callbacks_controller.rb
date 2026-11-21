# frozen_string_literal: true

# Apple's form_post back from the website's Sign in with Apple (see AppleWebSignInsController#start).
# The POST is cross-site, so it carries neither the session cookie nor a CSRF token: it is an API
# controller with no session, like AppleAccountsController. The signed OAuth state and the identity
# token's nonce authenticate it instead, and the ticket it returns can only be redeemed by the
# browser holding the photographer host's own sign-in nonce, as with Facebook.
#
# Like the apps, this never creates accounts: the Apple ID must already belong to an admin, linked
# from Chip or Cogsworth or matched by an Apple-verified email (User.from_apple).
class AppleWebCallbacksController < ActionController::API
  include TenantAuthReturn

  NOT_LINKED = "This Apple ID isn't linked to a Lumière admin yet. Sign in with Facebook once, then choose " \
               "Link Apple ID in Chip or Cogsworth."
  NOT_VERIFIED = "Sign in with Apple could not be verified. Try again."

  def create
    payload = verifier.verified(params[:state].to_s, purpose: AppleWebSignInsController::STATE_PURPOSE) if api_host?
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

  def verifier
    Rails.application.message_verifier(AppleWebSignInsController::STATE_PURPOSE)
  end
end
