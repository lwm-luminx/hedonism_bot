require 'rails_helper'

RSpec.describe "Graphql", type: :request do
  before do
    mock_photographer
  end

  describe "POST /graphql" do
    before do
      post "/graphql", params: { query: "{ __schema { types { name } } }" }
    end

    it "executes a query" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a valid response" do
      expect(JSON.parse(response.body)).to have_key("data")
    end
  end
end
