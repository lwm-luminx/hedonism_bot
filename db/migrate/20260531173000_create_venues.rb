class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :tenant, null: false, type: :uuid, foreign_key: true

      t.string :slug, null: false
      t.string :name, null: false
      t.text :description

      t.string :address
      t.st_point :coordinates, srid: 4326
    end

    add_index :venues, [:tenant_id, :slug], unique: true
    add_index :venues, [:tenant_id, :name]
  end
end
