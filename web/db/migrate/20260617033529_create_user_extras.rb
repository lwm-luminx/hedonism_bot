class CreateUserExtras < ActiveRecord::Migration[8.1]
  def change
    create_table :user_likes, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.references :page, type: :uuid, null: false, foreign_key: true, index: true
    end

    create_table :user_locations, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :venue, type: :uuid, foreign_key: true, index: true
      t.references :session, type: :uuid, null: false, foreign_key: true, index: true
      t.references :location, type: :uuid, foreign_key: true, index: true

      t.geography :point, limit: { srid: 4326, type: "st_point", geographic: true }
      t.boolean :beacon, default: false, null: false
    end

    create_table :user_pages, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.references :page, type: :uuid, null: false, foreign_key: true, index: true

      t.string :facebook_token, null: false
      t.boolean :administrator, default: false, null: false

      t.index [ :user_id, :page_id ], name: "index_user_pages_on_user_id_page_id", unique: true
    end

    create_table :user_rsvps, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.references :event, type: :uuid, null: false, foreign_key: true, index: true

      t.string :state, null: false

      t.index [ :user_id, :event_id ], name: "user_rsvps_user_id_event_id_uindex", unique: true
    end

    create_table :friendships, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.references :friend_high, type: :uuid, null: false, foreign_key: { to_table: :users }, index: true
      t.references :friend_low, type: :uuid, null: false, foreign_key: { to_table: :users }, index: true

      t.date :friends_at
      t.binary :friend_hash
      t.integer :weight
      t.boolean :is_circle, default: false, null: false

      t.index [ :friend_high_id, :friend_low_id ], unique: true
      t.index [ :friend_hash ], unique: true
    end

    create_table :friendship_links, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.references :friend, type: :uuid, null: false, foreign_key: { to_table: :users }, index: true

      t.references :friendship, type: :uuid, null: false, foreign_key: true, index: true

      t.index [ :friendship_id, :user_id, :friend_id ], unique: true
    end

    create_table :pings, id: :uuid, default: "gen_random_uuid()"  do |t|
      t.timestamps

      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.references :locale, type: :uuid, null: false, foreign_key: true, index: true

      t.boolean :is_safety, default: false, null: false
    end

    create_table :safety_reports, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.string :types, null: false, array: true

      t.geography :point, limit: { srid: 4326, type: "st_point", geographic: true }
    end

    create_table :safety_report_identifiers, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :safety_report, type: :uuid, null: false, foreign_key: true, index: true

      t.string :type, null: false
      t.string :value, null: false
    end

    create_table :social_links, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.uuid :object_id, null: false

      t.string :provider, null: false
      t.string :handle, null: false
      t.boolean :primary, default: false, null: false
    end

    create_table :social_updates, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :social_link, type: :uuid, null: false, foreign_key: true, index: true

      t.string :body, null: false
    end
  end
end
