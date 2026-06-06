class ApplicationController < ActionController::Base
  before_action :populate_tenant


  private

  def populate_tenant
    @tenant ||= default_tenant if Rails.env.development?
  end

  def default_tenant
    Tenant.find_or_create_by(subdomain: "localhost") do |t|
      t.name = "Local Development Tenant"
    end
  end
end
