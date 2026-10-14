class CreateServiceAccountsAndFinishUploads < ActiveRecord::Migration[8.1]
  def change
    # API tokens for unattended uploaders (the Mac SD card app); only a digest is stored.
    create_table :service_accounts, id: :uuid do |t|
      t.references :photographer, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end

    # Where a promise's uploads land, and which blob/photo take each uploaded file became.
    add_reference :photo_promises, :album, type: :uuid, foreign_key: true
    add_column :photo_promise_files, :blob_id, :uuid
    add_reference :photo_promise_files, :photo_take, type: :uuid, foreign_key: true
  end
end
