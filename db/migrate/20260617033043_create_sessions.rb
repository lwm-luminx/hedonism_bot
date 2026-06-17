class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :devices, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.string :device_type
      t.string :vendor_identifier
      t.macaddr :bluetooth_address
      t.macaddr :wifi_address
      t.string :model

      t.index [ :device_type, :vendor_identifier ], name: "devices_by_vendor", unique: true
    end

    create_table :sessions, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.uuid :token_key
      t.string :session_token

      t.references :audience, type: :uuid, null: false, foreign_key: true, index: true
      t.references :device, type: :uuid, null: true, foreign_key: true, index: true
      t.references :user, type: :uuid, null: true, foreign_key: true, index: true

      t.inet "origin_ip"
      t.geography "location", limit: { srid: 4326, type: "st_point", geographic: true }
      t.string "version"
      t.integer "build"

      t.index [ :token_key ], name: "index_sessions_on_token_id"
      t.index [ :audience_id, :device_id, :user_id ], name: "sessions_takes_audience_device_user_index", unique: true
    end
  end
end
