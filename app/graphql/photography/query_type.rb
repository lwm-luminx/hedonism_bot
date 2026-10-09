module Photography
  class QueryType < GraphQL::Schema::Object
    graphql_name "PhotographyQuery"
    field :contract_version, String, null: false
    field :integration_metadata, IntegrationMetadataType, null: false
    field :photographer, PhotographerType, null: true do
      argument :audience_id, ID, required: true
    end

    def contract_version
      "1"
    end

    def integration_metadata
      IntegrationMetadata.details
    end

    def photographer(audience_id:)
      grant = context[:photography_grant]
      raise GraphQL::ExecutionError, "Photography access denied" unless grant && grant.audience_id == audience_id

      grant.photographer
    end
  end
end
