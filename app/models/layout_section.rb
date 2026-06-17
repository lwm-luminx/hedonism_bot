# frozen_string_literal: true

class LayoutSection
  attr_accessor :title, :items

  def initialize(title)
    @title = title

    @items = []
  end
end
