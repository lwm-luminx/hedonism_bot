# frozen_string_literal: true

# Grants a user admin rights over one photographer's gallery.
class PhotographerAdmin < ApplicationRecord
  ROLES = %w[admin].freeze

  belongs_to :photographer
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
end
