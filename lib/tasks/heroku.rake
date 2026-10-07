namespace :heroku do
  # Heroku gives the app one Postgres database, so the Solid Cache, Queue and Cable configs in
  # config/database.yml share it with database_tasks: false. Load each Solid schema the first time.
  desc "Prepare the database and load any missing Solid Cache/Queue/Cable tables"
  task release: [ "db:prepare", :environment ] do
    { "cache" => "solid_cache_entries", "queue" => "solid_queue_jobs", "cable" => "solid_cable_messages" }.each do |name, table|
      next if ActiveRecord::Base.connection.table_exists?(table)

      puts "Loading db/#{name}_schema.rb"
      load Rails.root.join("db/#{name}_schema.rb")
    end
  end
end
