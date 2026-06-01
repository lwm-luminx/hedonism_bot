class AddVenueToPhotos < ActiveRecord::Migration[8.1]
  def change
    add_reference :photos, :venue, null: true, foreign_key: true
    add_index :photos, [ :tenant_id, :venue_id ]
  end
end
