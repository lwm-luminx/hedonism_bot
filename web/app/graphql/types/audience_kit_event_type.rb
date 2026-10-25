module Types
  class AudienceKitEventType < Types::BaseObject
    description "An AudienceKit event a photographer may link an album to."

    field :id, ID, null: false, description: "AudienceKit's event id"
    field :name, String, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: true
    field :end_at, GraphQL::Types::ISO8601DateTime, null: true
    field :venue_id, ID, null: true, description: "AudienceKit's id for its venue"
    field :is_canceled, Boolean, null: false

    def name = object["name"].to_s
    def id = object["id"]
    def start_at = object["startAt"]
    def end_at = object["endAt"]
    def venue_id = object["venueId"]
    def is_canceled = object["isCanceled"] == true
  end
end
