class AddUploadContextToAlbums < ActiveRecord::Migration[8.1]
  def change
    add_column :albums, :upload_context, :jsonb, default: {}, null: false
  end
end
