class CreateDeviceLoginGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :device_login_grants do |t|
      t.references :service_account, type: :uuid, null: false, foreign_key: true
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
    end
    add_index :device_login_grants, :code_digest, unique: true
  end
end
