# frozen_string_literal: true

# Register https://api.<SERVICE_DOMAIN>/auth/facebook/callback once in Facebook Login.
# Facebook Login for the admin console. The app ID and secret are resolved in facebook.rb.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           FACEBOOK_APP_ID,
           FACEBOOK_APP_SECRET,
           callback_url: "https://api.#{Rails.configuration.x.service_domain}/auth/facebook/callback",
           scope: "email,public_profile",
           info_fields: "name,email,first_name,last_name",
           client_options: {
             site: "https://graph.facebook.com/#{FACEBOOK_GRAPH_API_VERSION}",
             authorize_url: "https://www.facebook.com/#{FACEBOOK_GRAPH_API_VERSION}/dialog/oauth"
           }
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.on_failure = proc { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
