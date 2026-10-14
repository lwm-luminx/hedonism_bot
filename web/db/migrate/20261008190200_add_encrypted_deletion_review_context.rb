class AddEncryptedDeletionReviewContext < ActiveRecord::Migration[8.1]
  def change
    add_column :data_deletion_requests, :encrypted_review_context, :text
  end
end
