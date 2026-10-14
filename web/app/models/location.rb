# frozen_string_literal: true

class Location < ApplicationRecord
  belongs_to :photo_take
  has_one :venue, dependent: :nullify
  has_one :locale, dependent: :nullify

  def name
    google_location["name"]
  end

  def update_location(longitude, latitude)
    Rails.logger.debug { "Location => #{self}" }
    self.point = RGeo::Geographic.simple_mercator_factory.point longitude, latitude
  end

  def self.from_google_place_id(place_id)
    location = find_or_initialize_by google_place_id: place_id

    spot = GOOGLE_MAPS_CLIENT.spot place_id

    location.google_location = spot

    location.update_location spot["lng"], spot["lat"]
    location.save

    location
  end

  def self.from_name(name)
    place_id = GOOGLE_MAPS_CLIENT.spots_by_query(name).first.place_id
    from_google_place_id place_id
  end
end
