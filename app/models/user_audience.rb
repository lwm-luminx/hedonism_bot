# frozen_string_literal: true

class UserAudience < ApplicationRecord
  belongs_to :user
  belongs_to :audience
end
