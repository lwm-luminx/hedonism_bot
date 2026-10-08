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
    post "/auth/start"
    canonical = ActionDispatch::Integration::Session.new(Rails.application)
    canonical.get response.location
    canonical.post "/auth/facebook"
    canonical.follow_redirect!
    canonical.follow_redirect! if URI.parse(canonical.response.location).path == "/auth/failure"
    get canonical.response.location
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

    expect(response).to redirect_to("/admin?auth_error=access_denied")
  end

  # rubocop:disable RSpec/ExampleLength
  it "uses the shared redirect URI in the real Facebook authorization request", :aggregate_failures do
    OmniAuth.config.test_mode = false
    host! "luminx.lumiere.host"
    Photographer.create!(name: "Luminx", subdomain: "luminx")
    post "/auth/start"
    canonical = ActionDispatch::Integration::Session.new(Rails.application)
    previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    canonical.get response.location
    token = Nokogiri::HTML(canonical.response.body).at_css('input[name="authenticity_token"]')["value"]
    canonical.post "/auth/facebook", params: { authenticity_token: token }
    authorization = URI.parse(canonical.response.location)
    expect(authorization.host).to eq("www.facebook.com")
    expect(URI.decode_www_form(authorization.query).to_h).to include(
      "redirect_uri" => "https://api.lumiere.host/auth/facebook/callback"
    )
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery_protection
  end

  it "returns a custom-domain browser through the shared callback and rejects replay", :aggregate_failures do
    photographer.domains.create!(hostname: "gallery.luminx.com")
    host! "gallery.luminx.com"
    post "/auth/start"
    bridge_url = response.location
    expect(URI.parse(bridge_url).host).to eq("api.lumiere.host")

    # Separate cookie jars model the two unrelated domains.
    canonical = ActionDispatch::Integration::Session.new(Rails.application)
    canonical.host! "api.lumiere.host"
    canonical.get bridge_url
    expect(canonical.response).to have_http_status(:ok)
    canonical.post "/auth/facebook"
    canonical.follow_redirect!
    return_url = canonical.response.location
    expect(URI.parse(return_url).host).to eq("gallery.luminx.com")

    stranger = ActionDispatch::Integration::Session.new(Rails.application)
    stranger.get return_url
    expect(stranger.response).to have_http_status(:unauthorized)

    get return_url
    expect(response).to redirect_to("/admin")
    expect(me).to include("facebook_id" => "1234567890")
    get return_url
    expect(response).to have_http_status(:unauthorized)
  end

  # rubocop:enable RSpec/ExampleLength

  it "rejects unsigned bridge requests" do
    host! "api.lumiere.host"
    get "/auth/bridge", params: { ticket: "forged" }
    expect(response).to have_http_status(:bad_request)
  end
end
