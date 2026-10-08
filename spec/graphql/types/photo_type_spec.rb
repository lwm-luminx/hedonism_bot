require 'rails_helper'

RSpec.describe Types::PhotoType, type: :graphql do
  before do
    mock_photographer
  end

  let_it_be(:photos) { create_list(:photo_take, 5) }

  let(:query) do
    <<~GQL
      query {
        photos {
          nodes {
            id
            name
            price
            previewUrl
            takenAt
            folder { name }
            event { id }
          }
        }
      }
    GQL
  end

  describe "valid query" do
    before do
      execute_graphql(query)
    end

    it "types photos" do
      expect(data["photos"]["nodes"].length).to be(5)
    end

    it "resolves the fields the admin photos page asks for", :aggregate_failures do
      node = data["photos"]["nodes"].first
      expect(node["name"]).to match(/\ADSC\d+\.arw\z/)
      expect(node["folder"]).to eq("name" => "Default Album")
      expect(node["event"]).to be_nil
    end
  end
end
