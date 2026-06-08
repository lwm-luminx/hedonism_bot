require 'rails_helper'

RSpec.describe "GraphQL Photos Query", type: :request do
  before do
    mock_tenant
  end

  it "queries photos" do
    tenant = Tenant.default_tenant
    create(:photo, tenant: tenant)
    query = <<~GQL
      query {
        photos {
          id
        }
      }
    GQL
    post "/graphql", params: { query: query }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["data"]["photos"]).not_to be_empty
  end
end
