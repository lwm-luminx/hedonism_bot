# frozen_string_literal: true

module Types
  class BaseConnection < Types::BaseObject
    # add `nodes` and `pageInfo` fields, as well as `edge_type(...)` and `node_nullable(...)` overrides
    include GraphQL::Types::Relay::ConnectionBehaviors

    field :total_count, Integer, null: false, description: "The total number of items in the entire collection."

    def total_count
      # object.items is the original unpaginated relation/array
      object.items.size
    end
  end
end
