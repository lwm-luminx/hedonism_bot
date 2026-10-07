class ApplicationController < ActionController::Base
  before_action :set_photographer

  private

  def photographer
    Current.photographer
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
