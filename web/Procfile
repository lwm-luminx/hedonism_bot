release: bin/rails heroku:release
web: bundle exec puma -C config/puma.rb
worker: bundle exec rails solid_queue:start
