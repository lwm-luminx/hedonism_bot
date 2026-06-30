# frozen_string_literal: true

module LocationConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :location
    belongs_to :image

    def display_name
      location.google_location["name"]
    end

    def populate_from_google; end

    def update_location(longitude, latitude)
      Rails.logger.debug { "Location => #{self}" }
      location.point = RGeo::Geographic.simple_mercator_factory.point longitude, latitude
    end

    def update_location_geocode(street, zip)
      return if location.google_place_id || street.nil? || zip.nil?

      address = "#{street}, #{zip}, USA"
      Rails.logger.debug { "Geocoding => #{location}" }

      spot = Geocoder.coordinates address

      location.update_location spot[0], spot[1] if spot
      # self.google_place_id = spot['place_id']
      location.google_location = spot
      location
    end
  end

  class_methods do
    def closest(point, within: nil)
      if within
        close = joins(:location).where("ST_Within(?, locations.envelope::geometry)", point)
        return close.order("st_distance(locations.point, ?)", point).first
      end

      joins(:location).order("locations.point <-> ?", point).first
    end
  end
end
