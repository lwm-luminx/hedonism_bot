# frozen_string_literal: true

class UserPage < ApplicationRecord
  validates :facebook_token, presence: true

  belongs_to :user
  belongs_to :page
end
