class Photographer < ApplicationRecord
  has_many :photo_takes, dependent: :destroy
  has_many :photos
  has_many :albums, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :faces, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9-]*\z/, message: "must be lowercase alphanumeric/hyphen" }

  scope :active, -> { where("active IS TRUE") }

  def folders
    self.albums
  end

  def self.default_photographer
    Photographer.find_or_create_by(subdomain: "localhost") do |t|
      t.name = "Local Development Photographer"
    end
  end
end
