class Photographer < ApplicationRecord
  has_many :photo_takes, dependent: :destroy
  has_many :photos
  has_many :albums, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :faces, dependent: :destroy
  has_many :service_accounts, dependent: :destroy
  has_many :photographer_admins, dependent: :destroy
  has_many :admins, through: :photographer_admins, source: :user
  has_many :domains, class_name: "PhotographerDomain", dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9-]*\z/, message: "must be lowercase alphanumeric/hyphen" }

  scope :active, -> { where("active IS TRUE") }

  # The photographer whose site a request host serves: a registered domain first, then the host's
  # first label as a subdomain (sam.hedonism.bot → "sam").
  def self.for_host(host)
    host = host.to_s.downcase.delete_suffix(".")
    return if host.blank?

    PhotographerDomain.find_by(hostname: host)&.photographer || find_by(subdomain: host.split(".").first)
  end

  def owner_photographer_id
    id
  end

  def folders
    self.albums
  end

  def self.default_photographer
    Photographer.find_or_create_by(subdomain: "localhost") do |t|
      t.name = "Local Development Photographer"
    end
  end
end
