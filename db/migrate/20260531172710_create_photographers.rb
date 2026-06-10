class CreatePhotographers < ActiveRecord::Migration[8.1]
  def change
    create_table :photographers, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.string :name, null: false
      t.string :subdomain, null: false
      t.boolean :active, null: false, default: true
      t.string :api_key, null: false
    end

    add_index :photographers, :subdomain, unique: true
    add_index :photographers, :api_key, unique: true
  end
end
