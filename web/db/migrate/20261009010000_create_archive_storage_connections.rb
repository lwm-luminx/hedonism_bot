class CreateArchiveStorageConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :archive_storage_connections do |t|
      t.references :service_account, type: :uuid, null: false, foreign_key: true, index: false
      t.string :device_name, null: false
      t.jsonb :paths, null: false, default: []
      t.datetime :last_seen_at, null: false
      t.timestamps
    end
    add_index :archive_storage_connections, :service_account_id, unique: true, name: "index_archive_connections_on_account", if_not_exists: true
  end
end
