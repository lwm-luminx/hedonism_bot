# A hostname (e.g. gallery.luminx.media) that serves one photographer's site.
class PhotographerDomain < ApplicationRecord
  belongs_to :photographer

  normalizes :hostname, with: ->(hostname) { hostname.strip.downcase.delete_suffix(".") }

  validates :hostname, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+\z/, message: "must be a hostname" }
end
