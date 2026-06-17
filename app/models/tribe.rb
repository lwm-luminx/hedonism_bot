# frozen_string_literal: true

class Tribe < ApplicationRecord
  has_many :tribe_users, dependent: :destroy
end
