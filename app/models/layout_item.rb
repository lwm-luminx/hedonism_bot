# frozen_string_literal: true

class LayoutItem
  include ActiveModel::Model

  attr_accessor :id, :type, :title, :description, :height, :photo_url, :link_url, :distance, :start_at

  def initialize(type)
    @type = type
  end
end
