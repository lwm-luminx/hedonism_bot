# Browser-based Facebook authentication uses the existing OmniAuth registration. Only a short-lived
# PKCE-bound code returns to iOS; the API token is delivered by the HTTPS exchange. Apps may leave out
# the photographer: the exchange then returns the person's archives to choose from (ArchiveChoice).
class NativeAccountsController < ApplicationController
  skip_before_action :set_photographer
  # These endpoints authenticate with a PKCE grant or bearer token, never browser cookies.
  skip_forgery_protection only: [ :exchange, :destroy ]

  def new
    target = Photographer.find_by(subdomain: params[:photographer]) if params[:photographer].present?
    challenge = params[:challenge].to_s
    state = params[:state].to_s
    unless (target || params[:photographer].blank?) && challenge.match?(/\A[A-Za-z0-9_-]{43}\z/) &&
           state.match?(/\A[A-Za-z0-9_-]{32,128}\z/)
      return render plain: "Invalid sign-in request", status: :bad_request
    end

    session[:native_login] = { photographer_id: target&.id, challenge: challenge, state: state, expires_at: 5.minutes.from_now.to_i }
    render :new
  end

  def complete
    login = session.delete(:native_login)
    user = current_user
    target = login && login["photographer_id"] && Photographer.find_by(id: login["photographer_id"])
    allowed = target ? user&.admin_of?(target) : user && login && login["photographer_id"].nil? && ArchiveChoice.archives_for(user).any?
    unless login && login["expires_at"].to_i > Time.current.to_i && allowed
      return render plain: "Sign-in expired or you do not administer a Lumière archive", status: :unauthorized
    end

    code = SecureRandom.urlsafe_base64(32)
    NativeLoginGrant.create!(code_digest: Digest::SHA256.hexdigest(code), challenge: login["challenge"],
                             user: user, photographer: target, expires_at: 2.minutes.from_now)
    redirect_to "lumiere-uploader://signin?#{ { code: code, state: login['state'] }.to_query }", allow_other_host: true
  end

  def exchange
    body = NativeLoginGrant.exchange(code: params[:code], verifier: params[:verifier])
    return render json: { error: "Sign-in expired or invalid" }, status: :unauthorized unless body

    response.headers["Cache-Control"] = "no-store"
    render json: body
  end

  def destroy
    account = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return head :unauthorized unless account

    account.revoke!
    head :no_content
  end
end
