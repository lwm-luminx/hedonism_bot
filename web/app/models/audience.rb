# frozen_string_literal: true

class Audience < ApplicationRecord
  has_many :audience_users, dependent: :nullify
  has_many :audience_domains, dependent: :destroy
  has_many :users, dependent: :nullify, through: :audience_users

  validates :subdomain, presence: true
end
