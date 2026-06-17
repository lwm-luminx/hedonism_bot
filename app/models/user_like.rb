# frozen_string_literal: true

class UserLike < ApplicationRecord
  belongs_to :user
  belongs_to :page
end
