class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews, id: :uuid, default: "gen_random_uuid()" do |t|
      t.timestamps

      t.references :user, null: false, foreign_key: true, index: true, type: :uuid
      t.references :page, null: false, foreign_key: true, type: :uuid, index: true

      t.string :content, null: false

      t.index [ :user_id, :page_id ], unique: true
    end
  end
end
