# frozen_string_literal: true

class AudienceUser < ApplicationRecord
  belongs_to :audience
  belongs_to :user

  validates :facebook_token, presence: true
end
