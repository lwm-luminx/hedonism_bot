class CreateFaces < ActiveRecord::Migration[8.1]
  def change
    create_table :faces, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photographer, type: :uuid, null: false, foreign_key: true, index: true
      t.references :user, type: :uuid, null: true, foreign_key: true, index: true

      t.vector :arc_face_embedding, limit: 512, null: true

      t.index [ :arc_face_embedding ], using: :hnsw, opclass: :vector_cosine_ops
    end

    create_table :photo_faces, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps

      t.references :photo_take, type: :uuid, null: false, foreign_key: true, index: true
      t.references :face, type: :uuid, null: true, foreign_key: { on_delete: :nullify }, index: true

      t.float :confidence
      t.jsonb :bounding_box, null: false, default: {}
      t.vector :arc_face_embedding, limit: 512, null: true

      t.index [ :arc_face_embedding ], using: :hnsw, opclass: :vector_cosine_ops
      t.index [ :face_id, :photo_take_id ], name: "photo_faces_takes_face_id_index", unique: true
    end
  end
end
