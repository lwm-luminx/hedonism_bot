require "clusterkit/clusterkit.bundle"

class ClusterFacesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: nil

  def perform
    Face.delete_all

    hdbscan = ClusterKit::Clustering::HDBSCAN.new(
      min_samples: 5, # Minimum samples in neighborhood
      min_cluster_size: 10, # Minimum cluster size
      metric: "euclidean" # Distance metric
    )

    people = {} #: Hash[String, Face]

    photo_embeddings = PhotoFace.where("confidence > ?", 0.9).to_h { |p| [ p, p.arc_face_embedding ] }
    clusters = hdbscan.fit(photo_embeddings.values)
    ap clusters
    photo_embeddings.keys.zip(clusters.labels).to_h.each do |photo_person, cluster|
      next if cluster == -1

      people[cluster] ||= Person.create(photographer: photo_person.photo.photographer)
      photo_person.update(person: people[cluster]) unless PhotoFace.find_by(photo_id: photo_person.photo_id, person: people[cluster])
    end
  end
end
