class AddAppleSubToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :apple_sub, :string
    add_index :users, :apple_sub, unique: true
  end
end
