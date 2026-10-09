class AddNativeAccountSignIn < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_accounts, :user, type: :uuid, foreign_key: true
    create_table :native_login_grants do |t|
      t.string :code_digest, null: false
      t.string :challenge, null: false
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :photographer, type: :uuid, null: false, foreign_key: true
      t.datetime :expires_at, null: false
    end
    add_index :native_login_grants, :code_digest, unique: true
  end
end
