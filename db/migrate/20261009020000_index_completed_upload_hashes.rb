class IndexCompletedUploadHashes < ActiveRecord::Migration[8.1]
  def change
    add_index :photo_promise_files, :image_hash, where: "status = 'success'", name: "index_completed_upload_hashes"
  end
end
