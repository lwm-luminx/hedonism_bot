# Links an album to an AudienceKit venue, and event if one is listed, in each audience its photographer is connected
# to (one row per album and audience). Names and the start time are cached from AudienceKit for display only.
class CreateAlbumEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :album_events, id: :uuid do |t|
      t.references :album, type: :uuid, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.uuid :audience_id, null: false, comment: "The AudienceKit audience"
      t.string :audience_name
      t.uuid :audience_kit_venue_id, null: false
      t.string :venue_name
      t.uuid :audience_kit_event_id, comment: "Null when the album is linked to a venue with no listed event"
      t.string :event_name
      t.datetime :event_start_at
      t.timestamps
    end
    add_index :album_events, %i[album_id audience_id], unique: true
  end
end
