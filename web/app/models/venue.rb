# frozen_string_literal: true

class Venue < ApplicationRecord
  include LocationConcern

  has_one :page, dependent: :destroy, required: true

  has_many :events, lambda {
    where("start_at > ? OR end_at > ?", DateTime.now, DateTime.now).order(start_at: :asc)
  }, dependent: :destroy, inverse_of: :venue
  has_many :users, dependent: :nullify

  belongs_to :locale

  delegate :name, to: :page

  def phone_number
    location[:phone_number]
  end

  def street
    location[:street]
  end

  def open?
    return false unless location.google_location

    location.google_location["utc_offset"]

    location.google_location["opening_hours"]
  end

  def update_data
    return unless location.google_place_id

    location.update_location location.google_location["lng"], location.google_location["lat"]

    save
  end

  def hero_banner_url; end

  def update_envelope
    return unless location.point

    location.envelope = location.point.buffer(distance_tolerance)

    location.save
  end

  delegate :display_name, to: :page

  delegate :facebook_id, to: :page

  def to_layout
    venue = LayoutItem.new :venue
    venue.id = id
    venue.title = page.display_name
    venue.image_url = image.cdn_url
    venue.description = "You're the first to arrive."
    venue.link_url = "https://hotmess.social/venues/#{id}"
    venue.distance = self[:distance]
    venue
  end

  def self.from_seed(config)
    page = Page.page_for_facebook_id Koala::Facebook::API.new(FACEBOOK_APP_TOKEN), config[:facebook_id]
    raise "Cannot find page with ID #{config[:facebook_id]}" unless page
    venue = Venue.find_or_create_by page_id: page.id
    venue.google_place_id = config[:google_place_id]
    venue.save!

    venue
  end
end
