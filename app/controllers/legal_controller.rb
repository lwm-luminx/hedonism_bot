# frozen_string_literal: true

# Public notices must remain accessible without a session or a configured gallery.
class LegalController < ApplicationController
  skip_before_action :set_photographer
  layout false

  def privacy
  end

  def data_deletion
  end
end
