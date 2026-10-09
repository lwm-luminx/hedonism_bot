# Public metadata is shared by integration contracts, independently of photographer grants.
class IntegrationMetadataType < GraphQL::Schema::Object
  field :website_url, String, null: true
  field :company_name, String, null: true
  field :support_url, String, null: true
  field :support_email, String, null: true
end
