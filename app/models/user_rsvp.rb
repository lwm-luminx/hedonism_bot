# frozen_string_literal: true

class UserRsvp < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :state, presence: true

  after_initialize do
    self.state ||= "unsure"
  end
end
