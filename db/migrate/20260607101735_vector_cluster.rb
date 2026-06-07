class VectorCluster < ActiveRecord::Migration[8.1]
  def change
    remove_column :photo_people, :cluster_number

    add_index :photo_people, :arc_face_embedding, using: :hnsw, opclass: :vector_cosine_ops
    add_index :people, :arc_face_embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
