class CreatePhotographerDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :photographer_domains, id: :uuid do |t|
      t.references :photographer, null: false, foreign_key: true, type: :uuid
      t.string :hostname, null: false
      t.timestamps
    end
    add_index :photographer_domains, :hostname, unique: true
  end
end
