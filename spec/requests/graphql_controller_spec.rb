require 'rails_helper'

RSpec.describe "Graphql", type: :request do
  before do
    mock_tenant
  end

  describe "POST /graphql" do
    it "executes a query" do
      post "/graphql", params: { query: "{ __schema { types { name } } }" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key("data")
    end
  end
end
