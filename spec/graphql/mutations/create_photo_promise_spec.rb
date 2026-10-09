require 'rails_helper'

RSpec.describe Mutations::CreatePhotoPromise, type: :graphql do
  include_context 'when photo promise created'

  describe "with valid inputs" do
    before do
      execute_graphql(create_promise_query, context: uploader_context)
    end

    it "uploads with a set of file inputs" do
      expect(data.dig("createPhotoPromise", "promise", "id")).to be_present
    end
  end

  it "refuses visitors who aren't signed in" do
    execute_graphql(create_promise_query)

    expect(response_errors.first["message"]).to eq("Admin sign-in required")
  end

  it "accepts the photographer's signed-in admin" do
    photographer = Photographer.default_photographer
    admin = create(:user).tap { |u| PhotographerAdmin.create!(user: u, photographer: photographer, role: "admin") }
    execute_graphql(create_promise_query, context: { photographer: photographer, current_user: admin })

    expect(data.dig("createPhotoPromise", "promise", "id")).to be_present
  end
end
