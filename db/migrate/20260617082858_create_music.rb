class CreateMusic < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.timestamps

      t.references :social_link, null: false, foreign_key: true, type: :uuid, index: true
      t.references :image, type: :uuid, index: true, foreign_key: true
      t.references :waveform_image, type: :uuid, index: true, foreign_key: { to_table: :images }

      t.string :title, null: false
      t.string :provider_url, null: false
      t.string :provider_identifier, null: false
      t.string :download_url
      t.string :stream_url
      t.jsonb :metadata
    end
  end
end
