source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# HAML over ERB [https://haml.info]
gem "haml-rails"
# Use postgresql as the database for Active Record [https://github.com/ged/ruby-pg]
gem "pg", "~> 1.1"
# The clean, modern PostGIS adapter for Rails [https://github.com/seuros/activerecord-postgis]
gem "activerecord-postgis"
# Nearest neighbor search for Rails [https://github.com/ankane/neighbor]
gem "neighbor"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Vite makes running front ends easy [https://github.com/ElMassimo/vite_ruby]
gem "vite_rails"
# Redis is used to dispatch AI / ML tasks
gem "async"
gem "async-redis"
gem "redis"
gem "pg_search"
# clusterkit 0.3.1 never loads its native extension when compiled from source (as on Ruby 4):
# its fallback `require "clusterkit/clusterkit"` resolves to its own .rb file instead of the .so.
# On macOS 27, build it with CARGO=bin/cargo-chained-fixups (bin/setup does) or dyld rejects it.
# On Heroku the apt buildpack unpacks libclang under .apt. Point rb-sys's bindgen at it, and at
# clang's builtin headers (stdarg.h), which Ubuntu's libclang looks for under /usr/lib/llvm-*.
if (llvm_lib = Dir[File.join(__dir__, ".apt/usr/lib/llvm-*/lib")].first)
  ENV["LIBCLANG_PATH"] ||= llvm_lib
  if (clang_include = Dir[File.join(llvm_lib, "clang/*/include")].first)
    ENV["BINDGEN_EXTRA_CLANG_ARGS"] ||= "-isystem #{clang_include}"
  end
end
gem "clusterkit", "0.2.6"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "activejob-locking"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.0"
gem "ruby-vips"

gem "exifr"
gem "mini_exiftool"

gem "foreman", require: false

gem "aws-sdk-s3", require: false

gem "stripe"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

gem "koala"
gem "ticketmaster-sdk"
gem "google_maps_service"
gem "geocoder"
gem "pundit"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection"
gem "graphql"
gem "graphql-persisted_queries"

# GraphQL::Tracing::DetailedTrace (in the schema) needs protobuf in every environment.
gem "google-protobuf"

group :development, :test do
  gem "pry-rails"
  gem "awesome_print"
  gem "graphiql-rails"

  # Static Typing
  gem "rbs_rails"

  gem "rspec-rails"

  gem "rails-controller-testing"

  gem "factory_bot_rails"

  gem "faker"

  gem "shoulda-matchers"

  gem "capybara"
  gem "cucumber-rails", require: false
  gem "database_cleaner-active_record"
  gem "playwright-ruby-client"
  gem "webmock"

  gem "simplecov"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakåemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec"
  gem "rubocop-rake"
  gem "rubocop-performance"
  gem "rubocop-rbs_inline"

  gem "steep"
  gem "rbs-inline", require: false
end

group :test do
  gem "test-prof"
end

group :development do
  gem "web-console"
  gem "chrome_devtools_rails"
  gem "typeprof"
end
