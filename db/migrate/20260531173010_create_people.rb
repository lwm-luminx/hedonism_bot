class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photographer, type: :uuid, null: false, foreign_key: true

      t.string :first_name
      t.string :last_name
      t.string :name
      t.string :email

      t.string :facebook_id
      t.string :twitter_id
      t.string :instagram_id

      t.integer :cluster_number

      t.vector :arc_face_embedding, limit: 512, null: true
    end

    add_index :people, [ :photographer_id, :name ]

    create_table :photo_people, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photo, type: :uuid, null: false, foreign_key: true
      t.references :person, type: :uuid, null: true, foreign_key: { on_delete: :nullify }

      t.float :confidence
      t.jsonb :bounding_box, null: false, default: {}
      t.vector :arc_face_embedding, limit: 512
      t.integer :cluster_number, null: true
    end

    add_index :photo_people, [ :photo_id, :person_id ], unique: true
  end
end
