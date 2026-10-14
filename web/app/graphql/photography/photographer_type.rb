module Photography
  class PhotographerType < GraphQL::Schema::Object
    graphql_name "HedonismPhotographer"
    implements PhotographerInterface

    def grant_expires_at
      context[:photography_grant].expires_at
    end

    def photos(updated_since: nil)
      PhotoConnection.new(context[:photography_grant].publications(updated_since: updated_since))
    end
  end
end
