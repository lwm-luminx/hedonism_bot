# frozen_string_literal: true

class VenueMessage < ApplicationRecord
  belongs_to :user
  belongs_to :venue
end
