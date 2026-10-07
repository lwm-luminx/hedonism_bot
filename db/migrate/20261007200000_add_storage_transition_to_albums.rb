class AddStorageTransitionToAlbums < ActiveRecord::Migration[8.1]
  def change
    # "archiving" or "restoring" while an ArchiveAlbumJob moves the album's originals between tiers.
    add_column :albums, :storage_transition, :string
  end
end
