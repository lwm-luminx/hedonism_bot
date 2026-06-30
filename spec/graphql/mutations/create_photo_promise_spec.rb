require 'rails_helper'

RSpec.describe Mutations::CreatePhotoPromise, type: :graphql do
  include_context 'when photo promise created'

  describe "with valid inputs" do
    before do
      execute_graphql(create_promise_query)
    end

    it "uploads with a set of file inputs" do
      expect(data.dig("createPhotoPromise", "promise", "id")).to be_present
    end
  end
end
