# AudienceKit pulls published photos by keyset cursor and asks for changes since its last crawl, so a publication
# must outlive the photo it shared: unpublishing or deleting leaves a tombstone (removed_at) keyed by the photo's id
# (photo_key), which stays when the photo row goes. Grants can also carry an expiry.
class AddTombstonesToPhotographyPublications < ActiveRecord::Migration[8.1]
  def up
    change_table :photography_publications, bulk: true do |t|
      t.datetime :published_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :removed_at
      t.uuid :photo_key
    end
    execute "UPDATE photography_publications SET published_at = created_at, photo_key = photo_id"
    change_column_null :photography_publications, :photo_key, false
    change_column_null :photography_publications, :photo_id, true
    remove_foreign_key :photography_publications, :photos
    add_foreign_key :photography_publications, :photos, on_delete: :nullify
    remove_index :photography_publications, [ :photography_grant_id, :photo_id ]
    add_index :photography_publications, [ :photography_grant_id, :photo_key ], unique: true
    add_index :photography_publications, [ :photography_grant_id, :published_at, :photo_key ]
    add_index :photography_publications, [ :photography_grant_id, :updated_at ]

    add_column :photography_grants, :expires_at, :datetime
  end

  def down
    remove_column :photography_grants, :expires_at

    remove_index :photography_publications, [ :photography_grant_id, :updated_at ]
    remove_index :photography_publications, [ :photography_grant_id, :published_at, :photo_key ]
    remove_index :photography_publications, [ :photography_grant_id, :photo_key ]
    execute "DELETE FROM photography_publications WHERE photo_id IS NULL"
    add_index :photography_publications, [ :photography_grant_id, :photo_id ], unique: true
    remove_foreign_key :photography_publications, :photos
    add_foreign_key :photography_publications, :photos
    change_column_null :photography_publications, :photo_id, false
    change_table :photography_publications, bulk: true do |t|
      t.remove :published_at, :removed_at, :photo_key
    end
  end
end
