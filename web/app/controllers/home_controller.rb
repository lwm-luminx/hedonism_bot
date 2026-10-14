require "digest"

class HomeController < ApplicationController
  layout "application"

  def index
    render "home/index"
  end
end
