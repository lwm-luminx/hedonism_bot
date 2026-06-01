class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.string :address
      t.float :latitude
      t.float :longitude
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :venues, [ :tenant_id, :slug ], unique: true
    add_index :venues, [ :tenant_id, :name ]
  end
end
