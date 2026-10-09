module Photography
  class PhotographerType < GraphQL::Schema::Object
    graphql_name "HedonismPhotographer"
    implements PhotographerInterface

    def photos
      context[:photography_grant].published_photos
    end
  end
end
