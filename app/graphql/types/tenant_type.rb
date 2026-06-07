module Types
  class TenantType < BaseObject
    implements GraphQL::Types::Relay::Node

    field :id, ID, null: false, description: "The unique identifier for the tenant"
    field :name, String, null: false, description: "The name of the tenant"
    field :subdomain, String, null: false, description: "The subdomain of the tenant"
  end
end
