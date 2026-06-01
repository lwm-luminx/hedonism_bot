class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name
      t.string :external_ref
      # Facial embedding vector stored as a float array (e.g. 128/512-dim).
      t.float :embedding, array: true, default: []
      t.integer :embedding_dimensions
      t.string :embedding_model
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :people, [ :tenant_id, :name ]
    add_index :people, [ :tenant_id, :external_ref ], unique: true, where: "external_ref IS NOT NULL"
  end
end
