module Photography
  module PhotographerInterface
    include GraphQL::Schema::Interface
    graphql_name "IPhotographer"
    field :id, ID, null: false, description: "The photographer's opaque identifier; AudienceKit compares it case-insensitively."
    field :name, String, null: false
    field :grant_expires_at, GraphQL::Types::ISO8601DateTime, null: true,
                                                              description: "When the credential this request carries stops working; null when it does not expire."
    field :photos, PhotoType.connection_type, null: false, max_page_size: 50, default_page_size: 20,
                                              description: "Photos shared with the audience, oldest publication first, by keyset cursor on (publishedAt, id)." do
      argument :updated_since, GraphQL::Types::ISO8601DateTime, required: false,
                                                                description: "Only photos shared, changed or removed at or after this time, tombstones included."
    end
  end
end
