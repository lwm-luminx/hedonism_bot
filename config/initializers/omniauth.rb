# frozen_string_literal: true

# Facebook Login for the admin console. The app ID and secret come from FACEBOOK_APP_ID /
# FACEBOOK_APP_SECRET, falling back to `facebook.app_id` / `facebook.secret` in credentials.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           ENV.fetch("FACEBOOK_APP_ID") { Rails.application.credentials.dig(:facebook, :app_id) },
           ENV.fetch("FACEBOOK_APP_SECRET") { Rails.application.credentials.dig(:facebook, :secret) },
           scope: "email,public_profile",
           info_fields: "name,email,first_name,last_name"
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.on_failure = proc { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
