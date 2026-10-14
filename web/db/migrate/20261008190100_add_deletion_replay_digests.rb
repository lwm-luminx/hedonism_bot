class AddDeletionReplayDigests < ActiveRecord::Migration[8.1]
  def change
    add_column :data_deletion_requests, :replay_digests, :string, array: true, default: [], null: false
  end
end
