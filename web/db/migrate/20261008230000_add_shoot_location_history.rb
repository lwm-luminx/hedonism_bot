class AddShootLocationHistory < ActiveRecord::Migration[8.1]
  def change
    add_column :photo_promises, :location_recordings, :jsonb, default: [], null: false
    add_reference :photo_takes, :inferred_venue, type: :uuid, foreign_key: { to_table: :venues }
  end
end
