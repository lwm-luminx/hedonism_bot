# frozen_string_literal: true

# Signs admins in and out with Facebook. OmniAuth handles POST /auth/facebook and hands the
# result to #create on the callback.
class SessionsController < ApplicationController
  def show
    render json: { user: current_user && {
      name: current_user.name,
      facebook_id: current_user.facebook_id,
      admin: current_user.admin_of?(photographer)
    } }
  end

  def create
    auth = request.env["omniauth.auth"]
    graph = auth.extra.raw_info.to_h.merge("id" => auth.uid)
    user = User.from_facebook_graph(graph, token: auth.credentials.token)

    reset_session
    session[:user_id] = user.id
    redirect_to safe_return_path
  end

  def failure
    redirect_to "/admin?auth_error=#{CGI.escape(params[:message].to_s)}"
  end

  def destroy
    reset_session
    head :no_content
  end

  private

  def safe_return_path
    origin = request.env["omniauth.origin"].to_s
    path = URI.parse(origin).path if origin.present?
    path&.start_with?("/admin", "/upload") ? path : "/admin"
  rescue URI::InvalidURIError
    "/admin"
  end
end
