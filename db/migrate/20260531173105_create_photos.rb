class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :event_templates, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :venue, type: :uuid, null: false, foreign_key: true, index: true
      t.references :cover_image, type: :uuid, null: true, foreign_key: { to_table: :images }

      t.string :name
      t.datetime :start_at
      t.datetime :end_at
    end

    create_table :events, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :audience, type: :uuid, null: true, foreign_key: true, index: true
      t.references :page, type: :uuid, null: true, foreign_key: true, index: true
      t.references :venue, type: :uuid, null: false, foreign_key: true, index: true
      t.references :event_templates, null: true, type: :uuid, foreign_key: true, index: true
      t.references :cover_image, type: :uuid, null: true, foreign_key: { to_table: :images }

      t.string :name
      t.string :name_override
      t.datetime :start_at
      t.datetime :end_at
      t.jsonb :facebook_graph, null: false
      t.bigint :facebook_id, null: false
      t.integer :order, default: 1000, null: false
      t.boolean :is_featured, default: false, null: false

      t.index [ :facebook_id ], name: "index_events_on_facebook_id", unique: true
    end

    create_table :event_people, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :person, type: :uuid, null: false, index: true
      t.references :event, type: :uuid, null: false, index: true

      t.string :role, null: false

      t.index [ :person_id, :event_id, :role ], name: "event_people_role_person_event_id_uindex", unique: true
    end

    create_table :albums, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.string :name, null: false

      t.references :photographer, type: :uuid, null: false, foreign_key: true, index: true
      t.references :venue, type: :uuid, null: true, foreign_key: true, index: true
      t.references :event, type: :uuid, null: true, foreign_key: true, index: true
    end

    create_table :photos, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :album, type: :uuid, null: true, foreign_key: true, index: true
      t.float :price
    end

    create_table :photo_promise, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.string :status, null: false, default: "pending"
      t.string :upload_url, null: false, default: nil
      t.string :original_filename, null: false, default: nil
      t.string :content_type, null: false, default: nil
      t.binary :image_hash, null: true, default: nil
      t.integer :file_size_bytes, null: true, default: nil

      t.references :venue, type: :uuid, null: false, foreign_key: true, index: true
      t.references :photographer, type: :uuid, null: false, foreign_key: true, index: true
      t.references :event, type: :uuid, null: true, foreign_key: true, index: true
      t.references :photo, type: :uuid, null: true, foreign_key: true, index: true

      t.index [ :image_hash ], name: "photo_takes_image_hash_index"
    end

    create_table :photo_takes, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photo, type: :uuid, null: false, foreign_key: true, index: true

      t.string :original_filename
      t.string :content_type
      t.bigint :file_size_bytes
      t.binary :image_hash
      t.datetime :taken_at
      t.string :status, null: false, default: "pending"

      t.jsonb :exif_metadata, null: false, default: {}
      t.jsonb :facial_metadata, null: true, default: nil
      t.string :caption, null: true, default: nil
      t.string :description, null: true, default: nil
    end
  end
end
