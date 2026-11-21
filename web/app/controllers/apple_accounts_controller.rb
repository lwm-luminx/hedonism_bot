# frozen_string_literal: true

# Sign in with Apple for the native apps. Apple only identifies the person; they still have to be
# an admin of the photographer they sign in to. People who signed up with Facebook are matched by
# their Apple-verified email, or link their Apple ID from an app session (POST /auth/apple/link).
# No accounts are created here. These JSON endpoints authenticate with Apple's signed token and a
# bearer credential, never browser cookies, so they are an API controller without a session.
class AppleAccountsController < ActionController::API
  NOT_LINKED = "This Apple ID isn't linked to a Lumière admin yet. Sign in with Facebook or a device " \
               "code once, then choose Link Apple ID."

  CLIENT_NAME = "Lumière app (Apple)"

  # With a photographer (older app builds), signs in to that archive. Without one, returns a
  # credential for the person's only archive or their archives to choose from (ArchiveChoice).
  def exchange
    claims = AppleIdentityToken.verify(params[:identity_token], nonce: params[:nonce])
    user = User.from_apple(claims)
    body = sign_in_response(user) if user
    return render json: { error: exchange_error(user) }, status: :forbidden unless body

    response.headers["Cache-Control"] = "no-store"
    render json: body
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

  private

  def sign_in_response(user)
    return ArchiveChoice.response_for(user, client_name: CLIENT_NAME) if params[:photographer].blank?

    target = Photographer.find_by(subdomain: params[:photographer].to_s.strip.downcase)
    ArchiveChoice.issue(user, target, client_name: CLIENT_NAME) if target && user.admin_of?(target)
  end

  def exchange_error(user)
    return NOT_LINKED unless user

    params[:photographer].present? ? "You don't administer that archive." : ArchiveChoice::NO_ARCHIVES
  end
end
