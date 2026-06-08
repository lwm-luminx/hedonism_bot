require 'rails_helper'

RSpec.describe "GraphQL CaptionPhotoUpdate Mutation", type: :request do
  before do
    mock_tenant
  end

  UPDATE_PHOTO_CAPTION_GQL = <<~GQL
      mutation {
        photoCaptionUpdate(id: "#{photo.id}", caption: "New Caption") {
          photo {
            id
            caption
          }
        }
      }
    GQL

  it "updates a caption" do
    tenant = Tenant.default_tenant
    photo = create(:photo, tenant: tenant)

    post "/graphql", params: { query: UPDATE_PHOTO_CAPTION_GQL }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["data"]["photoCaptionUpdate"]["photo"]["caption"]).to eq("New Caption")
  end
end
