ActiveRecord::Schema[7.1].define(version: 1) do
  create_table "solid_cable_messages", id: :uuid, force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.binary "payload", limit: 536870912, null: false
    t.datetime "created_at", null: false
    t.integer "channel_hash", limit: 8, null: false

    t.index %w[channel], name: "index_solid_cable_messages_on_channel"
    t.index %w[channel_hash], name: "index_solid_cable_messages_on_channel_hash"
    t.index %w[created_at], name: "index_solid_cable_messages_on_created_at"
  end
end
