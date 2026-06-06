class DatabaseExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension "uuid-ossp" unless extension_enabled?("uuid-ossp")
    enable_extension "vector" unless extension_enabled?("vector")
    enable_extension "postgis" unless extension_enabled?("postgis")
  end
end
