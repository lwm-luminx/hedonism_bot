module Types
  class AudienceKitAudienceType < Types::BaseObject
    description "An AudienceKit audience that connected the photographer, with what they may link albums to there."

    field :id, ID, null: false, description: "AudienceKit's audience id"
    field :name, String, null: false
    field :events, [ Types::AudienceKitEventType ], null: false, description: "Events in the window asked for, newest first"
    field :venues, [ Types::AudienceKitVenueType ], null: false,
                                                 description: "Those events' venues, and venues matching the search or near the point"

    def id = object["id"]
    def name = object["name"].to_s
    def events = Array(object["events"]).select { |event| event.is_a?(Hash) && event["id"].is_a?(String) }
    def venues = Array(object["venues"]).select { |venue| venue.is_a?(Hash) && venue["id"].is_a?(String) }
  end
end
