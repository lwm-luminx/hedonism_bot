# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_17_083638) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "uuid-ossp"
  enable_extension "vector"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "albums", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id"
    t.string "name", null: false
    t.uuid "photographer_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.index ["event_id"], name: "index_albums_on_event_id"
    t.index ["photographer_id"], name: "index_albums_on_photographer_id"
    t.index ["venue_id"], name: "index_albums_on_venue_id"
  end

  create_table "applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_key", null: false
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_applications_on_api_key", unique: true
    t.index ["audience_id"], name: "index_applications_on_audience_id"
  end

  create_table "audience_admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["audience_id", "user_id", "role"], name: "index_audience_admins_on_audience_id_and_user_id_and_role", unique: true
    t.index ["audience_id"], name: "index_audience_admins_on_audience_id"
    t.index ["user_id"], name: "index_audience_admins_on_user_id"
  end

  create_table "audience_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.bigint "facebook_app_id", null: false
    t.string "facebook_app_secret", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_id"], name: "index_audience_applications_on_audience_id"
  end

  create_table "audience_clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_application_id", null: false
    t.datetime "created_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_application_id"], name: "index_audience_clients_on_audience_application_id"
    t.index ["token"], name: "index_audience_clients_on_token", unique: true
  end

  create_table "audience_domains", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.string "dns_name", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_id"], name: "index_audience_domains_on_audience_id"
    t.index ["dns_name"], name: "index_audience_domains_on_dns_name"
  end

  create_table "audience_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.bigint "facebook_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["audience_id", "user_id"], name: "index_audience_users_on_audience_id_and_user_id", unique: true
    t.index ["audience_id"], name: "index_audience_users_on_audience_id"
    t.index ["facebook_id"], name: "index_audience_users_on_facebook_id", unique: true
    t.index ["user_id"], name: "index_audience_users_on_user_id"
  end

  create_table "audiences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "audiences_subdomain_uindex", unique: true
  end

  create_table "devices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.macaddr "bluetooth_address"
    t.datetime "created_at", null: false
    t.string "device_type"
    t.string "model"
    t.datetime "updated_at", null: false
    t.string "vendor_identifier"
    t.macaddr "wifi_address"
    t.index ["device_type", "vendor_identifier"], name: "devices_by_vendor", unique: true
  end

  create_table "event_people", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.uuid "person_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_people_on_event_id"
    t.index ["person_id", "event_id", "role"], name: "event_people_role_person_event_id_uindex", unique: true
    t.index ["person_id"], name: "index_event_people_on_person_id"
  end

  create_table "event_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "cover_image_id"
    t.datetime "created_at", null: false
    t.datetime "end_at"
    t.string "name"
    t.datetime "start_at"
    t.datetime "updated_at", null: false
    t.uuid "venue_id", null: false
    t.index ["cover_image_id"], name: "index_event_templates_on_cover_image_id"
    t.index ["venue_id"], name: "index_event_templates_on_venue_id"
  end

  create_table "events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "audience_id"
    t.uuid "cover_image_id"
    t.datetime "created_at", null: false
    t.datetime "end_at"
    t.uuid "event_templates_id"
    t.jsonb "facebook_graph", null: false
    t.bigint "facebook_id", null: false
    t.boolean "is_featured", default: false, null: false
    t.string "name"
    t.string "name_override"
    t.integer "order", default: 1000, null: false
    t.uuid "page_id"
    t.datetime "start_at"
    t.datetime "updated_at", null: false
    t.uuid "venue_id", null: false
    t.index ["audience_id"], name: "index_events_on_audience_id"
    t.index ["cover_image_id"], name: "index_events_on_cover_image_id"
    t.index ["event_templates_id"], name: "index_events_on_event_templates_id"
    t.index ["facebook_id"], name: "index_events_on_facebook_id", unique: true
    t.index ["page_id"], name: "index_events_on_page_id"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "faces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.vector "arc_face_embedding", limit: 512
    t.datetime "created_at", null: false
    t.uuid "photographer_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["arc_face_embedding"], name: "index_faces_on_arc_face_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["photographer_id"], name: "index_faces_on_photographer_id"
    t.index ["user_id"], name: "index_faces_on_user_id"
  end

  create_table "friendship_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "friend_id", null: false
    t.uuid "friendship_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["friend_id"], name: "index_friendship_links_on_friend_id"
    t.index ["friendship_id", "user_id", "friend_id"], name: "idx_on_friendship_id_user_id_friend_id_5c9ac771a3", unique: true
    t.index ["friendship_id"], name: "index_friendship_links_on_friendship_id"
    t.index ["user_id"], name: "index_friendship_links_on_user_id"
  end

  create_table "friendships", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.binary "friend_hash"
    t.uuid "friend_high_id", null: false
    t.uuid "friend_low_id", null: false
    t.date "friends_at"
    t.boolean "is_circle", default: false, null: false
    t.integer "weight"
    t.index ["friend_hash"], name: "index_friendships_on_friend_hash", unique: true
    t.index ["friend_high_id", "friend_low_id"], name: "index_friendships_on_friend_high_id_and_friend_low_id", unique: true
    t.index ["friend_high_id"], name: "index_friendships_on_friend_high_id"
    t.index ["friend_low_id"], name: "index_friendships_on_friend_low_id"
  end

  create_table "images", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "cdn_url", null: false
    t.binary "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "mime_type", null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.index ["content_hash"], name: "photos_hash_uindex", unique: true
    t.index ["source_url"], name: "photos_source_url_index"
  end

  create_table "locales", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.integer "beacon_major"
    t.string "city_names", array: true
    t.datetime "created_at", null: false
    t.st_polygon "envelope", geographic: true
    t.string "label"
    t.uuid "location_id"
    t.string "name"
    t.integer "timezone_zulu_delta"
    t.datetime "updated_at", null: false
    t.index ["audience_id"], name: "index_locales_on_audience_id"
    t.index ["location_id", "audience_id"], name: "index_locales_on_location_id_and_audience_id"
    t.index ["location_id"], name: "index_locales_on_location_id"
  end

  create_table "location_beacons", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer "beacon_minor", null: false
    t.datetime "created_at", null: false
    t.uuid "location_id", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_location_beacons_on_location_id"
  end

  create_table "locations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_polygon "envelope", geographic: true
    t.jsonb "google_location", null: false
    t.string "google_place_id", null: false
    t.uuid "image_id"
    t.st_point "point", geographic: true
    t.datetime "updated_at", null: false
    t.index ["google_place_id"], name: "index_locations_on_google_place_id", unique: true
    t.index ["image_id"], name: "index_locations_on_image_id"
  end

  create_table "pages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "cover_image_id"
    t.datetime "created_at", null: false
    t.string "facebook_access_token"
    t.jsonb "facebook_graph", null: false
    t.bigint "facebook_id", null: false
    t.string "facets", array: true
    t.boolean "hidden", default: false, null: false
    t.uuid "image_id"
    t.string "last_update_error"
    t.string "name", null: false
    t.string "name_override"
    t.boolean "requires_user_token", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["cover_image_id"], name: "index_pages_on_cover_image_id"
    t.index ["facebook_id"], name: "index_pages_on_facebook_id", unique: true
    t.index ["image_id"], name: "index_pages_on_image_id"
  end

  create_table "people", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.boolean "global", default: false, null: false
    t.boolean "like_required", default: false, null: false
    t.integer "order", default: 1000, null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_id", "page_id"], name: "people_audience_page_id_uindex", unique: true
    t.index ["audience_id"], name: "index_people_on_audience_id"
    t.index ["page_id"], name: "index_people_on_page_id"
  end

  create_table "person_locales", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "locale_id", null: false
    t.uuid "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["locale_id"], name: "index_person_locales_on_locale_id"
    t.index ["person_id", "locale_id"], name: "person_locale_unique_key", unique: true
    t.index ["person_id"], name: "index_person_locales_on_person_id"
  end

  create_table "photo_faces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.vector "arc_face_embedding", limit: 512
    t.jsonb "bounding_box", default: {}, null: false
    t.float "confidence"
    t.datetime "created_at", null: false
    t.uuid "face_id"
    t.uuid "photo_take_id", null: false
    t.datetime "updated_at", null: false
    t.index ["arc_face_embedding"], name: "index_photo_faces_on_arc_face_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["face_id", "photo_take_id"], name: "photo_faces_takes_face_id_index", unique: true
    t.index ["face_id"], name: "index_photo_faces_on_face_id"
    t.index ["photo_take_id"], name: "index_photo_faces_on_photo_take_id"
  end

  create_table "photo_promise_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.integer "file_size_bytes"
    t.binary "image_hash"
    t.string "original_filename", null: false
    t.uuid "photo_promise_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "upload_url", null: false
    t.index ["image_hash"], name: "photo_takes_image_hash_index"
    t.index ["photo_promise_id"], name: "index_photo_promise_files_on_photo_promise_id"
  end

  create_table "photo_promises", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id"
    t.uuid "photographer_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.index ["event_id"], name: "index_photo_promises_on_event_id"
    t.index ["photographer_id"], name: "index_photo_promises_on_photographer_id"
    t.index ["venue_id"], name: "index_photo_promises_on_venue_id"
  end

  create_table "photo_takes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "caption"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "description"
    t.jsonb "exif_metadata", default: {}, null: false
    t.jsonb "facial_metadata"
    t.bigint "file_size_bytes"
    t.binary "image_hash"
    t.string "original_filename"
    t.uuid "photo_id"
    t.string "status", default: "pending", null: false
    t.datetime "taken_at"
    t.datetime "updated_at", null: false
    t.index ["photo_id"], name: "index_photo_takes_on_photo_id"
  end

  create_table "photographer_admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "photographer_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["photographer_id", "user_id", "role"], name: "idx_on_photographer_id_user_id_role_3d511b37cd", unique: true
    t.index ["photographer_id"], name: "index_photographer_admins_on_photographer_id"
    t.index ["user_id"], name: "index_photographer_admins_on_user_id"
  end

  create_table "photographers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_photographers_on_subdomain", unique: true
  end

  create_table "photos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "album_id"
    t.datetime "created_at", null: false
    t.float "price"
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_photos_on_album_id"
  end

  create_table "pings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_safety", default: false, null: false
    t.uuid "locale_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["locale_id"], name: "index_pings_on_locale_id"
    t.index ["user_id"], name: "index_pings_on_user_id"
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["page_id"], name: "index_reviews_on_page_id"
    t.index ["user_id", "page_id"], name: "index_reviews_on_user_id_and_page_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "safety_report_identifiers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "safety_report_id", null: false
    t.string "type", null: false
    t.string "value", null: false
    t.index ["safety_report_id"], name: "index_safety_report_identifiers_on_safety_report_id"
  end

  create_table "safety_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_point "point", geographic: true
    t.string "types", null: false, array: true
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.integer "build"
    t.datetime "created_at", null: false
    t.uuid "device_id"
    t.st_point "location", geographic: true
    t.inet "origin_ip"
    t.string "session_token"
    t.uuid "token_key"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "version"
    t.index ["audience_id", "device_id", "user_id"], name: "sessions_takes_audience_device_user_index", unique: true
    t.index ["audience_id"], name: "index_sessions_on_audience_id"
    t.index ["device_id"], name: "index_sessions_on_device_id"
    t.index ["token_key"], name: "index_sessions_on_token_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "social_links", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "handle", null: false
    t.uuid "object_id", null: false
    t.boolean "primary", default: false, null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
  end

  create_table "social_updates", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.uuid "social_link_id", null: false
    t.datetime "updated_at", null: false
    t.index ["social_link_id"], name: "index_social_updates_on_social_link_id"
  end

  create_table "ticket_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "available", default: true, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.uuid "event_id", null: false
    t.decimal "price"
    t.string "provider", null: false
    t.string "provider_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_ticket_types_on_event_id"
  end

  create_table "tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "quantity", default: 1, null: false
    t.uuid "ticket_type_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["ticket_type_id"], name: "index_tickets_on_ticket_type_id"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "tracks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "download_url"
    t.uuid "image_id"
    t.jsonb "metadata"
    t.string "provider_identifier", null: false
    t.string "provider_url", null: false
    t.uuid "social_link_id", null: false
    t.string "stream_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "waveform_image_id"
    t.index ["image_id"], name: "index_tracks_on_image_id"
    t.index ["social_link_id"], name: "index_tracks_on_social_link_id"
    t.index ["waveform_image_id"], name: "index_tracks_on_waveform_image_id"
  end

  create_table "tribe_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "tribe_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["tribe_id"], name: "index_tribe_users_on_tribe_id"
    t.index ["user_id"], name: "index_tribe_users_on_user_id"
  end

  create_table "tribes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_id"], name: "index_tribes_on_audience_id"
  end

  create_table "user_likes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["page_id"], name: "index_user_likes_on_page_id"
    t.index ["user_id"], name: "index_user_likes_on_user_id"
  end

  create_table "user_locations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.boolean "beacon", default: false, null: false
    t.datetime "created_at", null: false
    t.uuid "location_id"
    t.st_point "point", geographic: true
    t.uuid "session_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.index ["location_id"], name: "index_user_locations_on_location_id"
    t.index ["session_id"], name: "index_user_locations_on_session_id"
    t.index ["venue_id"], name: "index_user_locations_on_venue_id"
  end

  create_table "user_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "administrator", default: false, null: false
    t.datetime "created_at", null: false
    t.string "facebook_token", null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["page_id"], name: "index_user_pages_on_page_id"
    t.index ["user_id", "page_id"], name: "index_user_pages_on_user_id_page_id", unique: true
    t.index ["user_id"], name: "index_user_pages_on_user_id"
  end

  create_table "user_rsvps", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["event_id"], name: "index_user_rsvps_on_event_id"
    t.index ["user_id", "event_id"], name: "user_rsvps_user_id_event_id_uindex", unique: true
    t.index ["user_id"], name: "index_user_rsvps_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "culture"
    t.string "email_address"
    t.jsonb "facebook_graph"
    t.string "facebook_id", null: false
    t.string "facebook_scopes", array: true
    t.string "facebook_token"
    t.datetime "facebook_token_issued_at"
    t.string "first_name"
    t.string "gender"
    t.boolean "god_mode", default: false, null: false
    t.uuid "image_id"
    t.string "instagram_id"
    t.string "last_name"
    t.string "name"
    t.string "twitter_id"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["facebook_id"], name: "users_facebook_id_uindex", unique: true
    t.index ["image_id"], name: "index_users_on_image_id"
  end

  create_table "venue_messages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.uuid "venue_id", null: false
    t.index ["user_id"], name: "index_venue_messages_on_user_id"
    t.index ["venue_id"], name: "index_venue_messages_on_venue_id"
  end

  create_table "venues", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "audience_id", null: false
    t.datetime "created_at", null: false
    t.integer "distance_tolerance", default: 250, null: false
    t.boolean "hidden", default: false, null: false
    t.uuid "locale_id", null: false
    t.uuid "location_id", null: false
    t.integer "order", default: 1000, null: false
    t.uuid "page_id", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_id", "page_id"], name: "venues_audience_page_id_uindex", unique: true
    t.index ["audience_id"], name: "index_venues_on_audience_id"
    t.index ["locale_id"], name: "index_venues_on_locale_id"
    t.index ["location_id"], name: "index_venues_on_location_id"
    t.index ["page_id"], name: "index_venues_on_page_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "albums", "events"
  add_foreign_key "albums", "photographers"
  add_foreign_key "albums", "venues"
  add_foreign_key "applications", "audiences"
  add_foreign_key "audience_admins", "audiences"
  add_foreign_key "audience_admins", "users"
  add_foreign_key "audience_applications", "audiences"
  add_foreign_key "audience_clients", "audience_applications"
  add_foreign_key "audience_domains", "audiences"
  add_foreign_key "audience_users", "audiences"
  add_foreign_key "audience_users", "users"
  add_foreign_key "event_templates", "images", column: "cover_image_id"
  add_foreign_key "event_templates", "venues"
  add_foreign_key "events", "audiences"
  add_foreign_key "events", "event_templates", column: "event_templates_id"
  add_foreign_key "events", "images", column: "cover_image_id"
  add_foreign_key "events", "pages"
  add_foreign_key "events", "venues"
  add_foreign_key "faces", "photographers"
  add_foreign_key "faces", "users"
  add_foreign_key "friendship_links", "friendships"
  add_foreign_key "friendship_links", "users"
  add_foreign_key "friendship_links", "users", column: "friend_id"
  add_foreign_key "friendships", "users", column: "friend_high_id"
  add_foreign_key "friendships", "users", column: "friend_low_id"
  add_foreign_key "locales", "audiences"
  add_foreign_key "locales", "locations"
  add_foreign_key "location_beacons", "locations"
  add_foreign_key "locations", "images"
  add_foreign_key "pages", "images"
  add_foreign_key "pages", "images", column: "cover_image_id"
  add_foreign_key "people", "audiences"
  add_foreign_key "people", "pages"
  add_foreign_key "person_locales", "locales"
  add_foreign_key "person_locales", "people"
  add_foreign_key "photo_faces", "faces", on_delete: :nullify
  add_foreign_key "photo_faces", "photo_takes"
  add_foreign_key "photo_promise_files", "photo_promises"
  add_foreign_key "photo_promises", "events"
  add_foreign_key "photo_promises", "photographers"
  add_foreign_key "photo_promises", "venues"
  add_foreign_key "photo_takes", "photos"
  add_foreign_key "photographer_admins", "photographers"
  add_foreign_key "photographer_admins", "users"
  add_foreign_key "photos", "albums"
  add_foreign_key "pings", "locales"
  add_foreign_key "pings", "users"
  add_foreign_key "reviews", "pages"
  add_foreign_key "reviews", "users"
  add_foreign_key "safety_report_identifiers", "safety_reports"
  add_foreign_key "sessions", "audiences"
  add_foreign_key "sessions", "devices"
  add_foreign_key "sessions", "users"
  add_foreign_key "social_updates", "social_links"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "tickets", "ticket_types"
  add_foreign_key "tickets", "users"
  add_foreign_key "tracks", "images"
  add_foreign_key "tracks", "images", column: "waveform_image_id"
  add_foreign_key "tracks", "social_links"
  add_foreign_key "tribe_users", "tribes"
  add_foreign_key "tribe_users", "users"
  add_foreign_key "tribes", "audiences"
  add_foreign_key "user_likes", "pages"
  add_foreign_key "user_likes", "users"
  add_foreign_key "user_locations", "locations"
  add_foreign_key "user_locations", "sessions"
  add_foreign_key "user_locations", "venues"
  add_foreign_key "user_pages", "pages"
  add_foreign_key "user_pages", "users"
  add_foreign_key "user_rsvps", "events"
  add_foreign_key "user_rsvps", "users"
  add_foreign_key "users", "images"
  add_foreign_key "venue_messages", "users"
  add_foreign_key "venue_messages", "venues"
  add_foreign_key "venues", "audiences"
  add_foreign_key "venues", "locales"
  add_foreign_key "venues", "locations"
  add_foreign_key "venues", "pages"
end
