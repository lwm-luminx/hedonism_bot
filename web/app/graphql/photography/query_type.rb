module Photography
  class QueryType < GraphQL::Schema::Object
    # Major.minor: AudienceKit accepts any provider whose major part matches the version it registered, so additive
    # changes bump the minor part only.
    CONTRACT_VERSION = "1.2"

    graphql_name "PhotographyQuery"
    field :contract_version, String, null: false,
                                     description: "The provider contract this endpoint serves, major.minor; consumers match the major part."
    field :integration_metadata, IntegrationMetadataType, null: false
    field :photographer, PhotographerType, null: true, description: "The photographer the request's credential acts for, in this audience." do
      argument :audience_id, ID, required: true
    end

    def contract_version
      CONTRACT_VERSION
    end

    def integration_metadata
      IntegrationMetadata.details
    end

    def photographer(audience_id:)
      grant = context[:photography_grant]
      raise GraphQL::ExecutionError, "Photography access denied" unless grant&.for_audience?(audience_id)

      grant.photographer
    end
  end
end
