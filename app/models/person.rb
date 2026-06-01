class Person < ApplicationRecord
  belongs_to :tenant
  has_many :photo_people, dependent: :destroy
  has_many :photos, through: :photo_people

  validate :embedding_dimensions_match

  before_validation :set_embedding_dimensions

  scope :for_tenant, ->(tenant) { where(tenant: tenant) }
  scope :with_embedding, -> { where.not(embedding: []) }

  # Cosine similarity between this person's embedding and another vector.
  def cosine_similarity(other)
    return nil if embedding.blank? || other.blank? || embedding.length != other.length

    dot = embedding.zip(other).sum { |a, b| a * b }
    mag_a = Math.sqrt(embedding.sum { |x| x * x })
    mag_b = Math.sqrt(other.sum { |x| x * x })
    return nil if mag_a.zero? || mag_b.zero?

    dot / (mag_a * mag_b)
  end

  private

  def set_embedding_dimensions
    self.embedding_dimensions = embedding.length if embedding.present?
  end

  def embedding_dimensions_match
    return if embedding.blank? || embedding_dimensions.blank?
    return if embedding.length == embedding_dimensions

    errors.add(:embedding, "length must match embedding_dimensions")
  end
end
