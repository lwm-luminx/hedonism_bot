# frozen_string_literal: true

# Signs admins in and out with Facebook. OmniAuth handles POST /auth/facebook and hands the
# result to #create on the callback.
class SessionsController < ApplicationController
  def show
    user = current_user
    render json: { user: user && {
      name: user.name,
      facebook_id: user.facebook_id,
      admin: user.admin_of?(photographer)
    } }
  end

  def create
    auth = request.env["omniauth.auth"]
    graph = auth.extra.raw_info.to_h.merge("id" => auth.uid)
    user = User.from_facebook_graph(graph, token: auth.credentials.token)

    return return_to_tenant(user_id: user.id) if session[:auth_bridge]

    native_login = session[:native_login]
    reset_session
    session[:user_id] = user.id
    session[:native_login] = native_login if native_login
    redirect_to(native_login ? "/auth/native/complete" : safe_return_path)
  rescue User::DeletionPending
    return return_to_tenant(error: "deletion_pending") if session[:auth_bridge]

    reset_session
    redirect_to "/admin?auth_error=deletion_pending"
  end

  def failure
    return return_to_tenant(error: params[:message].to_s) if session[:auth_bridge]

    redirect_to "/admin?auth_error=#{CGI.escape(params[:message].to_s)}"
  end

  def destroy
    reset_session
    head :no_content
  end

  private

  def return_to_tenant(**result)
    context = session.delete(:auth_bridge)
    ticket = Rails.application.message_verifier(:tenant_auth).generate(context.merge(result.stringify_keys),
                                                                     purpose: :auth_return, expires_in: 1.minute)
    reset_session
    redirect_to "https://#{context['host']}/auth/return?#{ { ticket: ticket }.to_query }", allow_other_host: true
  end

  def resolve_photographer
    bridge = session[:auth_bridge]
    if bridge && bridge["expires_at"].to_i > Time.current.to_i && request.host == "api.#{Rails.configuration.x.service_domain}" && %w[create failure].include?(action_name)
      target = Photographer.for_host(bridge["host"])
      return target if target && target.id == bridge["photographer_id"]
    end

    login = session[:native_login]
    return Photographer.find_by(id: login["photographer_id"]) if login && %w[create failure].include?(action_name)

    super
  end

  def safe_return_path
    origin = request.env["omniauth.origin"].to_s
    path = URI.parse(origin).path if origin.present?
    path&.start_with?("/admin") ? path : "/admin"
  rescue URI::InvalidURIError
    "/admin"
  end
end
