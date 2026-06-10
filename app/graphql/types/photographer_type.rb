module Types
  class PhotographerType < BaseObject
    implements GraphQL::Types::Relay::Node

    field :name, String, null: false, description: "The name of the Photographer"
    field :subdomain, String, null: false, description: "The subdomain of the Photographer"
  end
end
