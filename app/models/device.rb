# frozen_string_literal: true

class Device < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :vendor_identifier, uniqueness: { scope: :device_type }
  validates :vendor_identifier, :device_type, presence: true

  def self.from_identifier(id, options = {})
    Device.find_or_create_by(vendor_identifier: id, device_type: options[:type])
  end
end
