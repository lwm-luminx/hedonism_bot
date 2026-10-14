# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
require "graphql/rake_task"

Rails.application.load_tasks

# RuboCop and Steep are development gems, absent from production installs such as Heroku's.
begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
end

begin
  require "steep/rake_task"
  Steep::RakeTask.new do |t|
    t.check.severity_level = :error
    t.watch
  end
rescue LoadError
end

GraphQL::RakeTask.new(
  schema_name: "HedonismBotSchema", # Replace with your actual Schema class name
  directory: "./app/graphql" # Directory where schema.graphql and schema.json will be saved
)
