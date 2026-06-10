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

ActiveRecord::Schema[8.1].define(version: 2026_06_07_101735) do
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

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.vector "arc_face_embedding", limit: 512
    t.integer "cluster_number"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "facebook_id"
    t.string "first_name"
    t.string "instagram_id"
    t.string "last_name"
    t.string "name"
    t.uuid "photographer_id", null: false
    t.string "twitter_id"
    t.datetime "updated_at", null: false
    t.index ["arc_face_embedding"], name: "index_people_on_arc_face_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["photographer_id", "name"], name: "index_people_on_photographer_id_and_name"
    t.index ["photographer_id"], name: "index_people_on_photographer_id"
  end

  create_table "photo_people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.vector "arc_face_embedding", limit: 512
    t.jsonb "bounding_box", default: {}, null: false
    t.float "confidence"
    t.datetime "created_at", null: false
    t.uuid "person_id"
    t.uuid "photo_id", null: false
    t.datetime "updated_at", null: false
    t.index ["arc_face_embedding"], name: "index_photo_people_on_arc_face_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["person_id"], name: "index_photo_people_on_person_id"
    t.index ["photo_id", "person_id"], name: "index_photo_people_on_photo_id_and_person_id", unique: true
    t.index ["photo_id"], name: "index_photo_people_on_photo_id"
  end

  create_table "photographers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_photographers_on_api_key", unique: true
    t.index ["subdomain"], name: "index_photographers_on_subdomain", unique: true
  end

  create_table "photos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "caption"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "description"
    t.jsonb "exif_metadata", default: {}, null: false
    t.jsonb "facial_metadata"
    t.bigint "file_size_bytes"
    t.date "folder_date", comment: "Date the photo was taken, used as folder grouping key"
    t.binary "image_hash"
    t.string "original_filename"
    t.uuid "photographer_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "taken_at"
    t.datetime "updated_at", null: false
    t.uuid "venue_id"
    t.index ["photographer_id", "folder_date"], name: "index_photos_on_photographer_id_and_folder_date"
    t.index ["photographer_id", "status"], name: "index_photos_on_photographer_id_and_status"
    t.index ["photographer_id", "venue_id"], name: "index_photos_on_photographer_id_and_venue_id"
    t.index ["photographer_id"], name: "index_photos_on_photographer_id"
    t.index ["venue_id"], name: "index_photos_on_venue_id"
  end

  create_table "venues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address"
    t.st_point "coordinates", srid: 4326
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "photographer_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["photographer_id", "name"], name: "index_venues_on_photographer_id_and_name"
    t.index ["photographer_id", "slug"], name: "index_venues_on_photographer_id_and_slug", unique: true
    t.index ["photographer_id"], name: "index_venues_on_photographer_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "people", "photographers"
  add_foreign_key "photo_people", "people", on_delete: :nullify
  add_foreign_key "photo_people", "photos"
  add_foreign_key "photos", "photographers"
  add_foreign_key "photos", "venues"
  add_foreign_key "venues", "photographers"
end
