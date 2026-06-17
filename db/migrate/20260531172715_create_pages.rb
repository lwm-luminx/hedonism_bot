class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :locations, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :image, null: true, type: :uuid, foreign_key: true

      t.string :google_place_id, null: false
      t.jsonb :google_location, null: false
      t.geography :point, limit: { srid: 4326, type: "st_point", geographic: true }
      t.geography :envelope, limit: { srid: 4326, type: "st_polygon", geographic: true }

      t.index [ :google_place_id ], name: "index_locations_on_google_place_id", unique: true
    end

    create_table :location_beacons, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :location, null: false, type: :uuid, foreign_key: true, index: true

      t.integer :beacon_minor, null: false
    end

    create_table :locales, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :location, null: true, type: :uuid, foreign_key: true, index: true
      t.references :audience, null: false, type: :uuid, foreign_key: true, index: true

      t.string :label
      t.string :name
      t.integer :beacon_major
      t.geography :envelope, limit: { srid: 4326, type: "st_polygon", geographic: true }
      t.integer :timezone_zulu_delta
      t.string :city_names, array: true

      t.index [ :location_id, :audience_id ], name: "index_locales_on_location_id_and_audience_id"
    end

    create_table :pages, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :image, null: true, type: :uuid, foreign_key: true
      t.references :cover_image, null: true, type: :uuid, foreign_key: { to_table: :images }

      t.string :name, null: false
      t.string :name_override
      t.bigint :facebook_id, null: false
      t.jsonb :facebook_graph, null: false
      t.string :facebook_access_token
      t.string :facets, array: true
      t.boolean :requires_user_token, default: false, null: false
      t.boolean :hidden, default: false, null: false
      t.string :last_update_error

      t.index [ :facebook_id ], name: "index_pages_on_facebook_id", unique: true
    end

    create_table :venues, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :locale, null: false, type: :uuid, foreign_key: true, index: true
      t.references :location, null: false, type: :uuid, foreign_key: true, index: true
      t.references :page, null: false, type: :uuid, foreign_key: true, index: true
      t.references :audience, null: false, type: :uuid, foreign_key: true, index: true

      t.boolean :hidden, default: false, null: false
      t.integer :order, default: 1000, null: false
      t.integer :distance_tolerance, default: 250, null: false

      t.index [ :audience_id, :page_id ], name: "venues_audience_page_id_uindex", unique: true
    end

    create_table :venue_messages, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :venue, null: false, type: :uuid, foreign_key: true, index: true
      t.references :user, null: false, type: :uuid, foreign_key: true, index: true

      t.string :message
    end

    create_table :people, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :audience, null: false, type: :uuid, foreign_key: true, index: true
      t.references :page, null: false, type: :uuid, foreign_key: true, index: true

      t.integer :order, default: 1000, null: false
      t.boolean :global, default: false, null: false
      t.boolean :like_required, default: false, null: false

      t.index [ :audience_id, :page_id ], name: "people_audience_page_id_uindex", unique: true
    end

    create_table :person_locales, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :person, null: false, type: :uuid, foreign_key: true, index: true
      t.references :locale, null: false, type: :uuid, foreign_key: true, index: true

      t.index [ :person_id, :locale_id ], name: "person_locale_unique_key", unique: true
    end
  end
end
