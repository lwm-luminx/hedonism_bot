# Browser-based Facebook authentication uses the existing OmniAuth registration. Only a short-lived
# PKCE-bound code returns to iOS; the API token is delivered by the HTTPS exchange.
class NativeAccountsController < ApplicationController
  skip_before_action :set_photographer
  # These endpoints authenticate with a PKCE grant or bearer token, never browser cookies.
  skip_forgery_protection only: [ :exchange, :destroy ]

  def new
    target = Photographer.find_by(subdomain: params[:photographer])
    challenge = params[:challenge].to_s
    state = params[:state].to_s
    unless target && challenge.match?(/\A[A-Za-z0-9_-]{43}\z/) && state.match?(/\A[A-Za-z0-9_-]{32,128}\z/)
      return render plain: "Invalid sign-in request", status: :bad_request
    end

    session[:native_login] = { photographer_id: target.id, challenge: challenge, state: state, expires_at: 5.minutes.from_now.to_i }
    render :new
  end

  def complete
    login = session.delete(:native_login)
    user = current_user
    target = login && Photographer.find_by(id: login["photographer_id"])
    unless login && login["expires_at"].to_i > Time.current.to_i && user&.admin_of?(target) && target
      return render plain: "Sign-in expired or you do not administer this photographer", status: :unauthorized
    end

    code = SecureRandom.urlsafe_base64(32)
    NativeLoginGrant.create!(code_digest: Digest::SHA256.hexdigest(code), challenge: login["challenge"],
                             user: user, photographer: target, expires_at: 2.minutes.from_now)
    redirect_to "lumiere-uploader://signin?#{ { code: code, state: login['state'] }.to_query }", allow_other_host: true
  end

  def exchange
    pair = NativeLoginGrant.exchange(code: params[:code], verifier: params[:verifier])
    return render json: { error: "Sign-in expired or invalid" }, status: :unauthorized unless pair

    account, token = pair
    render json: { token: token, subdomain: account.photographer.subdomain, name: account.photographer.name }
  end

  def destroy
    account = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return head :unauthorized unless account

    account.revoke!
    head :no_content
  end
end
