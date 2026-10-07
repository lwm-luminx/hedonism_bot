class ApplicationController < ActionController::Base
  attr_reader :photographer

  private

  # The photographer whose gallery this request's host serves, or nil.
  def tenant_photographer
    photographer = Photographer.find_by(subdomain: request.subdomain)
    photographer ||= Photographer.default_photographer if Rails.env.development?
    photographer
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def photographer
    subdomain = request.hostname&.split(".")&.first
    @photographer ||= Photographer.find_by(subdomain: subdomain) || Photographer.default_photographer if Rails.env.development?

    @photographer or raise "No Photographer found (subdomain: #{subdomain})"
  end
end
