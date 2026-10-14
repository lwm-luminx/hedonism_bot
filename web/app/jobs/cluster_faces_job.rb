class ClusterFacesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: nil

  def perform
    PrivacyLock.biometric do
      # Keep identified faces: deleting them loses the user mapping needed for erasure.
      Face.where(user_id: nil).destroy_all
      Photographer.find_each do |photographer|
        candidates = PhotoFace.joins(photo_take: { photo: :album })
                              .where(albums: { photographer_id: photographer.id })
                              .where(photo_takes: { face_processing_disabled: false })
                              .where(face_id: nil).where("confidence > ?", 0.9)
                              .where.not(arc_face_embedding: nil).to_a
        next if candidates.size < 10

        hdbscan = ClusterKit::Clustering::HDBSCAN.new(min_samples: 5, min_cluster_size: 10, metric: "euclidean")
        clusters = hdbscan.fit_predict(candidates.map(&:arc_face_embedding))
        faces = {}
        candidates.zip(clusters).each do |photo_face, cluster|
          next if cluster == -1
          faces[cluster] ||= Face.create!(photographer: photographer)
          next if PhotoFace.exists?(photo_take_id: photo_face.photo_take_id, face_id: faces[cluster].id)
          photo_face.update!(face: faces[cluster])
        end
      end
    end
  end
end
