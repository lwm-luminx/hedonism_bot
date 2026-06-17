class DatabaseExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension "uuid-ossp"
    enable_extension "vector"
    enable_extension "postgis"
    enable_extension "plpgsql"
  end
end
