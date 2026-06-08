class Tenant < ApplicationRecord
  has_many :photos, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :people, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9-]*\z/, message: "must be lowercase alphanumeric/hyphen" }
  validates :api_key, presence: true, uniqueness: true

  before_validation :ensure_api_key, on: :create

  scope :active, -> { where(active: true) }

  def folders
    self.photos.group_by(&:folder_date).map { |folder, photos| Folder.new(folder, photos) }
  end

  def self.default_tenant
    Tenant.find_or_create_by(subdomain: "localhost") do |t|
      t.name = "Local Development Tenant"
    end
  end

  private

  def ensure_api_key
    self.api_key ||= SecureRandom.hex(24)
  end
end
