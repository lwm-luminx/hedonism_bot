require 'rails_helper'

RSpec.describe Types::PhotoType, type: :graphql do
  before do
    mock_photographer
  end

  let_it_be(:photos) { create_list(:photo, 5) }

  let(:query) do
    <<~GQL
      query {
        photos {
          id
        }
      }
    GQL
  end

  describe "valid query" do
    before do
      execute_graphql(query)
    end

    it "types photos" do
      expect(data["photos"].length).to be(5)
    end
  end
end
