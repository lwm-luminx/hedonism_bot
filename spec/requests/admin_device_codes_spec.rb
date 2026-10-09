require 'rails_helper'

RSpec.describe "Admin device pairing", type: :request do
  let!(:photographer) { create(:photographer, subdomain: "pairing") }
  let!(:user) { User.create!(facebook_id: "pairing-user", name: "Pairing admin") }

  before do
    host! "pairing.lumiere.host"
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
      provider: "facebook", uid: user.facebook_id, credentials: { token: "test-token" },
      extra: { raw_info: { "id" => user.facebook_id, "name" => user.name } }
    )
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  def sign_in
    post "/auth/start"
    canonical = ActionDispatch::Integration::Session.new(Rails.application)
    canonical.get response.location
    canonical.post "/auth/facebook"
    canonical.follow_redirect!
    get canonical.response.location
  end

  it "requires a browser session" do
    post "/admin/device_codes"
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an admin of another photographer" do
    other = create(:photographer)
    PhotographerAdmin.create!(user: user, photographer: other, role: "admin")
    sign_in
    post "/admin/device_codes"
    expect(response).to have_http_status(:forbidden)
  end

  it "issues a usable code scoped to the browser photographer", :aggregate_failures do
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    sign_in
    post "/admin/device_codes"
    account, = DeviceLoginGrant.exchange(code: response.parsed_body["code"])
    expect(account).to have_attributes(photographer: photographer, user: user)
  end
end
