module Photography
  class PhotoType < GraphQL::Schema::Object
    graphql_name "PhotographyPhoto"
    description "A logical Photo containing takes, as shared with an audience; never a PhotoTake of the gallery API. " \
                "With photos(updatedSince:), a photo that was unpublished or deleted is still listed, as a tombstone " \
                "(removed: true, no takes, no preview), so a consumer can drop it without re-crawling."
    field :id, ID, null: false, description: "The photo's opaque, stable identifier; the same across pages and crawls."
    field :take_count, Integer, null: false, description: "Processed takes of the photo; 0 for a tombstone."
    field :preview_url, String, null: true,
                                description: "A stable HTTPS link to the current preview (redirects to the stored image); null without one."
    field :removed, Boolean, null: false, method: :removed?,
                             description: "The photo is no longer shared with this audience: drop it."
    field :published_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When it was shared; the page order."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false,
                                                        description: "When it was last shared, changed or removed; feed it back as updatedSince."
  end
end
