class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :images, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.string :source_url, null: false
      t.binary :content_hash, null: false
      t.string :mime_type, null: false
      t.string :cdn_url, null: false

      t.index [ :content_hash ], name: "photos_hash_uindex", unique: true
      t.index [ :source_url ], name: "photos_source_url_index"
    end

    create_table :users, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :image, type: :uuid, null: true, foreign_key: true

      t.string :facebook_id, null: false
      t.string :twitter_id
      t.string :instagram_id
      t.string :facebook_token
      t.datetime :facebook_token_issued_at
      t.string :name
      t.string :email_address
      t.string :gender
      t.string :first_name
      t.string :last_name
      t.string :culture
      t.jsonb :facebook_graph, null: false, default: {}
      t.string :facebook_scopes, array: true
      t.boolean :god_mode, default: false, null: false

      t.index [ :email_address ], name: "index_users_on_email_address", unique: true
      t.index [ :facebook_id ], name: "users_facebook_id_uindex", unique: true
    end

    create_table :photographers, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.string :name, null: false
      t.string :subdomain, null: false
      t.boolean :active, null: false, default: true

      t.index :subdomain, unique: true
    end

    create_table :photographer_admins, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photographer, type: :uuid, null: false, foreign_key: true, index: true
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true

      t.string :role, null: false

      t.index [ :photographer_id, :user_id, :role ], unique: true
    end

    create_table :audiences, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.string :name, null: false
      t.string :subdomain, null: false

      t.index [ :subdomain ], name: "audiences_subdomain_uindex", unique: true
    end

    create_table :applications, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience, type: :uuid, null: false, foreign_key: true, index: true

      t.string :api_key, null: false

      t.index [ :api_key ], name: "index_applications_on_api_key", unique: true
    end

    create_table :audience_applications, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience, type: :uuid, null: false, foreign_key: true, index: true

      t.string :name, null: false
      t.bigint :facebook_app_id, null: false
      t.string :facebook_app_secret, null: false
    end

    create_table :audience_clients, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience_application, type: :uuid, null: false, foreign_key: true, index: true

      t.string :token, null: false

      t.index [ :token ], unique: true
    end

    create_table :audience_domains, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience,  type: :uuid, null: false, foreign_key: true, index: true

      t.string :dns_name, null: false

      t.index [ :dns_name ], name: "index_audience_domains_on_dns_name"
    end

    create_table :audience_users, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience, type: :uuid, null: false, foreign_key: true, index: true
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true

      t.bigint :facebook_id, null: false

      t.index [ :audience_id, :user_id ], unique: true
      t.index [ :facebook_id ], unique: true
    end

    create_table :audience_admins, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience, type: :uuid, null: false, foreign_key: true, index: true
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true

      t.string :role, null: false

      t.index [ :audience_id, :user_id, :role ], unique: true
    end
  end
end
