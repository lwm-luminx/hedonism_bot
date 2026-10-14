class ApplicationController < ActionController::Base
  before_action :set_photographer

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id], deletion_pending_at: nil)
  end

  def photographer
    Current.photographer || raise(ActiveRecord::RecordNotFound, "No photographer for this request")
  end

  # Every request is served for one photographer (tenant), picked by its host; unknown hosts get a 404.
  def set_photographer
    Current.photographer = resolve_photographer
    render plain: "Not found", status: :not_found unless performed? || Current.photographer
  end

  def resolve_photographer
    Photographer.for_host(request.host) || (Photographer.default_photographer if Rails.env.development?)
  end
end
