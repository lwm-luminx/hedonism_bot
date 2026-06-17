# frozen_string_literal: true

class EventPerson < ApplicationRecord
  validates :role, presence: true

  belongs_to :person
  belongs_to :event
end
