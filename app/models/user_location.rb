# frozen_string_literal: true

class UserLocation < ApplicationRecord
  validates :point, presence: true

  belongs_to :session
  belongs_to :venue
  belongs_to :location

  scope :recent, -> { where("created_at > ?", 2.hours.ago) }

  delegate :user, to: :session
end
