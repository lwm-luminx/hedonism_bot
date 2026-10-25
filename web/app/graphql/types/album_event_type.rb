module Types
  class AlbumEventType < Types::BaseObject
    description "Where an album is in one AudienceKit audience: its venue, and event if one is listed."

    field :audience_id, ID, null: false
    field :audience_name, String, null: true
    field :venue_id, ID, null: false, method: :audience_kit_venue_id
    field :venue_name, String, null: true
    field :event_id, ID, null: true, method: :audience_kit_event_id
    field :event_name, String, null: true
    field :event_start_at, GraphQL::Types::ISO8601DateTime, null: true
  end
end
