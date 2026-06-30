# frozen_string_literal: true

class Locale < ApplicationRecord
  ZIP_EXPRESSION = /\d{5}/

  include LocationConcern

  has_many :venues, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :events, through: :venues
  has_many :locations, dependent: :nullify

  belongs_to :location

  def update_envelope
    return unless venues.any?

    factory = RGeo::Geographic.simple_mercator_factory

    venue_points = venues.where(hidden: false).map(&:location).map(&:point).compact.to_a
    all_points = factory.collection venue_points
    envelope = all_points.envelope
    self.envelope = envelope
  end

  def from_locale_name(name, locale:)
    location = Geocoder.search(name).first if ZIP_EXPRESSION =~ name
    location ||= Locale.where("? = ANY(city_names)", locale).first&.location&.point
    raise "Location not able to be found" unless location

    point = RGeo::Geographic.simple_mercator_factory.point location.longitude, location.latitude

    Locale.closest(point)
  end

  def self.from_seed(label, name)
    Geocoder.search(name).first if ZIP_EXPRESSION =~ name

    Locale.find_or_create_by(label: label) do |l|
      l.location ||= Location.from_name name
    end
  end
end
