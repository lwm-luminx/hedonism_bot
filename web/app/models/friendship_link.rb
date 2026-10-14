# frozen_string_literal: true

class FriendshipLink < ApplicationRecord
  belongs_to :friendship
  belongs_to :user
  belongs_to :friend, class_name: "User"
end
