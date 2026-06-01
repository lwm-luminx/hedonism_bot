class CreatePhotoPeople < ActiveRecord::Migration[8.1]
  def change
    create_table :photo_people do |t|
      t.references :photo, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      # Per-detection data: bounding box, confidence, and the embedding for this face occurrence.
      t.float :confidence
      t.jsonb :bounding_box, null: false, default: {}
      t.float :embedding, array: true, default: []

      t.timestamps
    end

    add_index :photo_people, [ :photo_id, :person_id ], unique: true
  end
end
