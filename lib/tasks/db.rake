namespace :db do
  desc "Reset the database"
  task reset: [ "db:drop", "db:schema:load:queue", "db:prepare" ]
end
