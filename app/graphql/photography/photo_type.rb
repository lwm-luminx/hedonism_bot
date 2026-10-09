module Photography
  class PhotoType < GraphQL::Schema::Object
    graphql_name "PhotographyPhoto"
    description "A logical Photo containing takes; never a legacy GraphQL Photo (PhotoTake)."
    field :id, ID, null: false
    field :take_count, Integer, null: false
    field :preview_url, String, null: true

    def take_count
      object.processed_takes.size
    end

    def preview_url
      object.processed_takes.first&.preview_url
    end
  end
end
