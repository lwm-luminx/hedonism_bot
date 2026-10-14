class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_types, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :event, null: false, foreign_key: true, index: true, type: :uuid

      t.string :description
      t.decimal :price
      t.boolean :available, default: true, null: false
      t.string :provider, null: false
      t.string :provider_id, null: false
    end

    create_table :tickets, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :ticket_type, null: false, foreign_key: true, index: true, type: :uuid
      t.references :user, null: false, foreign_key: true, index: true, type: :uuid

      t.integer :quantity, null: false, default: 1
    end
  end
end
