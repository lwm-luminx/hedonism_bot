class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photographer, type: :uuid, null: false, foreign_key: true
      t.references :venue, type: :uuid, null: true, foreign_key: true

      t.string :original_filename
      t.string :content_type
      t.bigint :file_size_bytes
      t.binary :image_hash
      t.datetime :taken_at
      t.date :folder_date, comment: "Date the photo was taken, used as folder grouping key"
      t.string :status, null: false, default: "pending"

      t.jsonb :exif_metadata, null: false, default: {}
      t.jsonb :facial_metadata, null: true, default: nil
      t.string :caption, null: true, default: nil
      t.string :description, null: true, default: nil
    end

    add_index :photos, [ :photographer_id, :folder_date ]
    add_index :photos, [ :photographer_id, :status ]
    add_index :photos, [ :photographer_id, :venue_id ]
  end
end
