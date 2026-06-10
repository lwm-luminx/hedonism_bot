class ApplicationController < ActionController::Base
  attr_reader :photographer

  private

  def photographer
    subdomain = request.hostname&.split(".")&.first
    @photographer ||= Photographer.find_by(subdomain: subdomain) || Photographer.default_photographer if Rails.env.development?

    @photographer or raise "No Photographer found (subdomain: #{subdomain})"
  end
end
