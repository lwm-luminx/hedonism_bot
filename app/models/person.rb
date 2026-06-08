class Person < ApplicationRecord
  belongs_to :tenant
  has_many :photo_people, dependent: :nullify
  has_many :photos, through: :photo_people

  scope :for_tenant, ->(tenant) { where(tenant: tenant) }
  scope :with_embedding, -> { where.not(embedding: []) }

  has_neighbors :arc_face_embedding, dimensions: 512, normalize: true

  def self.cluster
    Person.delete_all

    hdbscan = ClusterKit::Clustering::HDBSCAN.new(
      min_samples: 5, # Minimum samples in neighborhood
      min_cluster_size: 10, # Minimum cluster size
      metric: "euclidean" # Distance metric
    )

    people = {}

    photo_embeddings = PhotoPerson.where("confidence > ?", 0.9).to_h { |p| [p, p.arc_face_embedding] }
    clusters = hdbscan.fit_predict(photo_embeddings.values)
    photo_embeddings.keys.zip(clusters).to_h.each do |photo_person, cluster|
      next if cluster == -1

      people[cluster] ||= Person.create(tenant: photo_person.photo.tenant)
      photo_person.update(person: people[cluster]) unless PhotoPerson.find_by(photo_id: photo_person.photo_id, person: people[cluster])
    end
  end
end
