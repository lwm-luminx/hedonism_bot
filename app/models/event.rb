# frozen_string_literal: true

require "English"

class Event < ApplicationRecord
  EVENT_FIELDS = %w[ticket_uri owner name cover start_time end_time place is_canceled].freeze

  EVYY_URI = /ticketmaster\.evyy\.net/
  TICKETMASTER_URI = %r{.+ticketmaster\.com/event/([0-9A-F]+)(\?.+)?}
  EVENTBRITE_URI = %r{.+eventbrite\.com/e/.+-(\d+)\??.*}

  validates :name, presence: true

  belongs_to :venue
  has_many :event_people, dependent: :destroy
  has_many :ticket_types, dependent: :destroy
  has_many :people, through: :event_people
  has_many :user_rsvps, dependent: :destroy
  belongs_to :cover_photo, class_name: "PhotoTake"

  delegate :locale, to: :venue

  scope :future, -> { where("start_at > ? OR end_at > ?", DateTime.now, DateTime.now).order(start_at: :asc) }

  def update_details_from_facebook
    self.start_at = facebook_graph["start_time"]
    self.end_at = facebook_graph["end_time"]
    self.name = facebook_graph["name"]

    save
  end

  def display_name
    name_override || name
  end

  def person
    first = event_people.first

    first&.person
  end

  def update_tickets
    url = facebook_graph["ticket_uri"]

    if EVYY_URI.match? url
      parsed_uri = Rack::Utils.parse_query(URI(url).query)
      url = parsed_uri["u"]
    end

    case url
    when TICKETMASTER_URI
      update_ticketmaster($LAST_MATCH_INFO[1])
    when EVENTBRITE_URI
      update_eventbrite($LAST_MATCH_INFO[1])
    end
  end

  def update_eventbrite(event_id)
    Rails.logger.debug { "Eventbrite #{event_id}" }
    Eventbrite::Event.retrieve(event_id)

    ticket_types.find_or_create_by(provider: "eventbrite", provider_id: event_id)
  end

  def update_ticketmaster(event_id)
    Rails.logger.debug { "Ticketmaster #{event_id}" }
    event = TICKETMASTER_CLIENT.get_event(event_id, version: "v1")
    Rails.logger.debug event.name

    ticket_types.find_or_create_by(provider: "ticketmaster", provider_id: event_id)
  end

  def to_english
    "starting at <say-as interpret-as='time'>#{start_at.strftime('%H:%M')}</say-as>, #{name} hosted by #{venue.name}"
  end

  def to_layout(featured: false)
    event = LayoutItem.new featured ? :featured_event : :event
    event.id = id
    event.title = display_name
    event.photo_url = cover_photo&.cdn_url
    event.link_url = "https://hotmess.social/events/#{id}"
    event.height = 60
    event.start_at = start_at

    event
  end
end
