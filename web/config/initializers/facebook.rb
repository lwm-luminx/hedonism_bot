# frozen_string_literal: true

# The Graph API version for Facebook Login (omniauth.rb) and Koala calls. Unversioned calls would
# fall back to the app's dashboard default.
FACEBOOK_GRAPH_API_VERSION = "v26.0"

Koala.configure do |config|
  config.api_version = FACEBOOK_GRAPH_API_VERSION
end

# Facebook app credentials live under `<env>.facebook` in credentials (e.g. `production.facebook.secret`),
# with a top-level `facebook` section as a fallback. FACEBOOK_APP_ID / FACEBOOK_APP_SECRET override both.
FACEBOOK_CREDENTIALS = Rails.application.credentials.dig(Rails.env.to_sym, :facebook) ||
                       Rails.application.credentials[:facebook] || {}
FACEBOOK_APP_ID = ENV.fetch("FACEBOOK_APP_ID") { FACEBOOK_CREDENTIALS[:app_id] }
FACEBOOK_APP_SECRET = ENV.fetch("FACEBOOK_APP_SECRET") { FACEBOOK_CREDENTIALS[:secret] }
