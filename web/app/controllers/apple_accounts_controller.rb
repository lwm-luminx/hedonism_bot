# frozen_string_literal: true

# Sign in with Apple for the native apps. Apple only identifies the person; they still have to be
# an admin of the photographer they sign in to. People who signed up with Facebook are matched by
# their Apple-verified email, or link their Apple ID from an app session (POST /auth/apple/link).
# No accounts are created here.
class AppleAccountsController < ApplicationController
  NOT_LINKED = "This Apple ID isn't linked to an admin of that archive. Sign in with Facebook or a device " \
               "code once, then choose Link Apple ID."

  skip_before_action :set_photographer
  skip_forgery_protection

  def exchange
    claims = AppleIdentityToken.verify(params[:identity_token], nonce: params[:nonce])
    target = Photographer.find_by(subdomain: params[:photographer].to_s.strip.downcase)
    user = User.from_apple(claims)
    return render json: { error: NOT_LINKED }, status: :forbidden unless target && user&.admin_of?(target)

    account, token = ServiceAccount.issue!(photographer: target, name: "Lumière app (Apple)")
    account.update!(user: user)
    response.headers["Cache-Control"] = "no-store"
    render json: { token: token, subdomain: target.subdomain, name: target.name }
  rescue AppleIdentityToken::Invalid
    render json: { error: "Sign in with Apple could not be verified. Try again." }, status: :unauthorized
  end

  def link
    account = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return render json: { error: "Sign in again, then link your Apple ID." }, status: :unauthorized unless account&.user

    claims = AppleIdentityToken.verify(params[:identity_token], nonce: params[:nonce])
    owner = User.find_by(apple_sub: claims.sub)
    if owner && owner != account.user
      return render json: { error: "This Apple ID is already linked to another person." }, status: :conflict
    end

    account.user.update!(apple_sub: claims.sub)
    head :no_content
  rescue AppleIdentityToken::Invalid
    render json: { error: "Sign in with Apple could not be verified. Try again." }, status: :unauthorized
  end
end
