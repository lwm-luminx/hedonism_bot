class CreateDataDeletionRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :deletion_pending_at, :datetime
    add_column :photo_takes, :face_processing_disabled, :boolean, default: false, null: false
    create_table :data_deletion_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :confirmation_code, null: false
      t.string :app_id, null: false
      t.string :subject_digest, null: false
      t.string :payload_digest, null: false
      t.uuid :user_id
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :next_attempt_at
      t.datetime :local_deleted_at
      t.datetime :completed_at
      t.datetime :reviewed_at
      t.jsonb :cleanup_manifest, null: false, default: []
      t.jsonb :review_reasons, null: false, default: []
      t.string :error_category
      t.timestamps
    end
    add_index :data_deletion_requests, :confirmation_code, unique: true
    add_index :data_deletion_requests, [ :app_id, :payload_digest ], unique: true
    add_index :data_deletion_requests, [ :app_id, :subject_digest ]
    add_index :data_deletion_requests, [ :status, :next_attempt_at ]
    # Deliberately no user FK: a receipt must survive erasure of the user.
  end
end
