require 'rails_helper'

RSpec.describe "Facebook admin sign-in", type: :request do
  let!(:photographer) { Photographer.create!(name: "Rick", subdomain: "rick") }

  before do
    host! "rick.lumiere.host"
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
      provider: "facebook", uid: "1234567890", credentials: { token: "fb-token" },
      extra: { raw_info: { "id" => "1234567890", "name" => "Rick Mark", "first_name" => "Rick", "last_name" => "Mark", "email" => "rick@example.com" } }
    )
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  def sign_in
    post "/auth/facebook"
    follow_redirect!
  end

  def me
    get "/auth/me"
    response.parsed_body["user"]
  end

  it "reports no user before sign-in" do
    expect(me).to be_nil
  end

  it "creates the user and returns to the admin console", :aggregate_failures do
    expect { sign_in }.to change(User, :count).by(1)
    expect(response).to redirect_to("/admin")
    expect(User.last).to have_attributes(facebook_id: "1234567890", email_address: "rick@example.com", facebook_token: "fb-token")
  end

  it "is not an admin until granted for this photographer", :aggregate_failures do
    sign_in
    expect(me).to include("name" => "Rick Mark", "facebook_id" => "1234567890", "admin" => false)

    PhotographerAdmin.create!(user: User.find_by!(facebook_id: "1234567890"), photographer: photographer, role: "admin")
    expect(me).to include("admin" => true)
  end

  it "does not carry admin rights to another photographer's host" do
    sign_in
    other = Photographer.create!(name: "Other", subdomain: "other")
    PhotographerAdmin.create!(user: User.find_by!(facebook_id: "1234567890"), photographer: other, role: "admin")

    expect(me).to include("admin" => false)
  end

  it "rejects an existing cookie once account deletion is accepted" do
    sign_in
    DataDeletionRequest.accept!({ "user_id" => "1234567890" }, "signed-payload")
    expect(me).to be_nil
  end

  it "signs out", :aggregate_failures do
    sign_in
    delete "/auth/session"

    expect(response).to have_http_status(:no_content)
    expect(me).to be_nil
  end

  it "sends failures back to the admin console with a message" do
    OmniAuth.config.mock_auth[:facebook] = :access_denied
    sign_in
    follow_redirect!

    expect(response).to redirect_to("/admin?auth_error=access_denied")
  end
end
