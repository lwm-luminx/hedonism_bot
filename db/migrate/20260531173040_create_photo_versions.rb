class CreatePhotoVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :photo_versions do |t|
      t.references :photo, null: false, foreign_key: true
      t.string :variant, null: false, comment: "e.g. original, thumbnail, small, medium, large, web"
      t.string :format, comment: "e.g. jpeg, png, webp, avif, heic"
      t.string :content_type
      t.integer :width
      t.integer :height
      t.bigint :byte_size
      t.string :checksum
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :photo_versions, [ :photo_id, :variant, :format ], unique: true
  end
end
