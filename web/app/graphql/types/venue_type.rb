module Types
  class VenueType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :name, String
    field :city, String
    field :address, String
    field :events, EventType.connection_type
  end
end
