# frozen_string_literal: true

class LocationBeacon < ApplicationRecord
  has_one :venue, dependent: :nullify
end
