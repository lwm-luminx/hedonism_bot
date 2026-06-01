class Venue < ApplicationRecord
  belongs_to :tenant
  has_many :photos, dependent: :nullify

  validates :name, presence: true
  validates :slug, uniqueness: { scope: :tenant_id, allow_nil: true },
                   format: { with: /\A[a-z0-9][a-z0-9-]*\z/, allow_nil: true }

  scope :for_tenant, ->(tenant) { where(tenant: tenant) }
end
