# frozen_string_literal: true

# The Graph API version for Facebook Login (omniauth.rb) and Koala calls. Unversioned calls would
# fall back to the app's dashboard default.
FACEBOOK_GRAPH_API_VERSION = "v26.0"

Koala.configure do |config|
  config.api_version = FACEBOOK_GRAPH_API_VERSION
end
