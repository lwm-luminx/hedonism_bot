module Types
  class EventType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    field :name, String
    field :date, GraphQL::Types::ISO8601DateTime
    field :venue, VenueType
  end
end
