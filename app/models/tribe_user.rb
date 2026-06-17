# frozen_string_literal: true

# Junction that connects a user to a "Tribe" or a self identification of a subculture
# (broadly similar to a hashtag)
class TribeUser < ApplicationRecord
  belongs_to :tribe
  belongs_to :user
end
