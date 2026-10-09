class CreatePhotographyGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :photography_grants, id: :uuid do |t|
      t.references :photographer, type: :uuid, null: false, foreign_key: true
      t.uuid :audience_id, null: false
      t.string :token_digest, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :photography_grants, :token_digest, unique: true
    create_table :photography_publications, id: :uuid do |t|
      t.references :photography_grant, type: :uuid, null: false, foreign_key: true
      t.references :photo, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    add_index :photography_publications, [ :photography_grant_id, :photo_id ], unique: true
  end
end
