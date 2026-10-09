class CreatePhotoInferenceWorks < ActiveRecord::Migration[8.1]
  def change
    create_table :photo_inference_works, id: :uuid do |t|
      t.references :photographer, type: :uuid, null: false, foreign_key: true
      t.references :photo_take, type: :uuid, null: false, foreign_key: true
      t.references :service_account, type: :uuid, foreign_key: true
      t.string :task, null: false
      t.string :state, null: false, default: "pending"
      t.string :lease_token
      t.datetime :lease_expires_at
      t.datetime :deadline_at
      t.integer :attempts, null: false, default: 0
      t.timestamps
    end
    add_index :photo_inference_works, [ :photo_take_id, :task ], unique: true
    add_index :photo_inference_works, [ :photographer_id, :state, :lease_expires_at ], name: "index_inference_work_dispatch"
  end
end
