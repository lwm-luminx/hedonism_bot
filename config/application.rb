require_relative "boot"

require "rails/all"
require_relative "../lib/middleware/facebook_deletion_body_limit"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HedonismBot
  class Application < Rails::Application
    config.active_record.query_log_tags_enabled = true
    config.active_record.query_log_tags = [
      # Rails query log tags:
      :application, :controller, :action, :job,
      # GraphQL-Ruby query log tags:
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class }
    ]
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.middleware.insert_before Rails::Rack::Logger, Middleware::FacebookDeletionBodyLimit

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Cheaper storage that photo originals can be moved to (see StorageTier and config/storage.yml).
    config.x.archive_storage_service = ENV["ARCHIVE_BUCKET_NAME"].present? ? :archive : nil

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Admin sign-in (Facebook via OmniAuth) needs a cookie-backed session, which api_only strips out.
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: "_hedonism_bot_session", same_site: :lax

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
