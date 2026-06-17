class CreateTribes < ActiveRecord::Migration[8.1]
  def change
    create_table :tribes, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :audience, null: false, type: :uuid, foreign_key: true, index: true

      t.string :name, null: false
      t.string :description, null: false
    end

    create_table :tribe_users, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :tribe, null: false, type: :uuid, foreign_key: true, index: true
      t.references :user, null: false, type: :uuid, foreign_key: true, index: true
    end
  end
end
