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

    reset_session
    session[:user_id] = user.id
    redirect_to safe_return_path
  rescue User::DeletionPending
    reset_session
    redirect_to "/admin?auth_error=deletion_pending"
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
    path&.start_with?("/admin") ? path : "/admin"
  rescue URI::InvalidURIError
    "/admin"
  end
end
