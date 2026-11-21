require "rails_helper"
require "webmock/rspec"

RSpec.describe "Sign in with Apple on the website", type: :request do
  let!(:photographer) { Photographer.create!(name: "Rick", subdomain: "rick") }
  let!(:user) { User.create!(facebook_id: "web-apple-facebook", name: "Apple tester", email_address: "tester@example.com") }
  let(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JWT::JWK.new(key, kid: "apple-web-test-key") }
  # Separate cookie jar: api.lumiere.host and the photographer's host don't share cookies.
  let(:canonical) { ActionDispatch::Integration::Session.new(Rails.application).tap { |s| s.host! "api.lumiere.host" } }

  def identity_token(nonce:, **claims)
    payload = { iss: "https://appleid.apple.com", aud: "host.lumiere.web", sub: "001234.web-sub",
                iat: Time.current.to_i, exp: 5.minutes.from_now.to_i, nonce: nonce,
                email: "tester@example.com", email_verified: true }.merge(claims)
    JWT.encode(payload.compact, key, "RS256", kid: jwk.kid)
  end

  # Starts sign-in on the photographer's host and follows it to Apple. Returns Apple's authorize params.
  def start_apple_sign_in
    post "/auth/start", params: { provider: "apple" }
    canonical.get response.location
    canonical.post "/auth/apple"
    authorize = URI.parse(canonical.response.location)
    [ authorize, URI.decode_www_form(authorize.query).to_h ]
  end

  # Apple's form_post. A fresh session models the cross-site POST, which carries no Lax session cookie.
  def apple_callback(params)
    apple = ActionDispatch::Integration::Session.new(Rails.application)
    apple.host! "api.lumiere.host"
    apple.post "/auth/apple/callback", params: params
    apple.response
  end

  def me
    get "/auth/me"
    response.parsed_body["user"]
  end

  before do
    host! "rick.lumiere.host"
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    stub_request(:get, "https://appleid.apple.com/auth/keys")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { keys: [ jwk.export ] }.to_json)
  end

  it "shows the bridge page with Apple's button", :aggregate_failures do
    post "/auth/start", params: { provider: "apple" }
    canonical.get response.location
    expect(canonical.response.body).to include("Continue with Apple", 'action="/auth/apple"')
    expect(canonical.response.body).not_to include("Continue with Facebook")
  end

  it "sends the browser to Apple with the Services ID and a hashed nonce", :aggregate_failures do
    authorize, query = start_apple_sign_in
    expect(authorize.host).to eq("appleid.apple.com")
    expect(query).to include("client_id" => "host.lumiere.web", "response_mode" => "form_post",
                             "redirect_uri" => "https://api.lumiere.host/auth/apple/callback")
    expect(query["nonce"]).to match(/\A\h{64}\z/)
  end

  def return_url_after_apple(**claims)
    _, query = start_apple_sign_in
    apple_callback(state: query["state"], id_token: identity_token(nonce: query["nonce"], **claims), code: "unused").location
  end

  it "signs an admin in to the photographer's host", :aggregate_failures do
    return_url = return_url_after_apple
    expect(URI.parse(return_url).host).to eq("rick.lumiere.host")
    get return_url
    expect(me).to include("admin" => true, "facebook_id" => "web-apple-facebook")
    expect(user.reload.apple_sub).to eq("001234.web-sub")
  end

  it "only completes in the browser that started sign-in" do
    stranger = ActionDispatch::Integration::Session.new(Rails.application).tap { |s| s.host! "rick.lumiere.host" }
    stranger.get return_url_after_apple
    expect(stranger.response).to have_http_status(:unauthorized)
  end

  it "explains when the Apple ID isn't linked to anyone" do
    get return_url_after_apple(email: "abc@privaterelay.appleid.com", is_private_email: true)
    expect(response.location).to include("auth_error=", CGI.escape("isn't linked"))
  end

  it "refuses a token whose nonce doesn't belong to this sign-in", :aggregate_failures do
    _, query = start_apple_sign_in
    get apple_callback(state: query["state"], id_token: identity_token(nonce: Digest::SHA256.hexdigest("other"))).location
    expect(response.location).to include("auth_error=")
    expect(me).to be_nil
  end

  it "refuses a token issued to one of the apps instead of the website" do
    get return_url_after_apple(aud: "host.lumiere.Chip")
    expect(me).to be_nil
  end

  it "returns a cancelled sign-in to the admin console" do
    _, query = start_apple_sign_in
    get apple_callback(state: query["state"], error: "user_cancelled_authorize").location
    expect(response.location).to include("auth_error=")
  end

  it "rejects a forged state" do
    expect(apple_callback(state: "forged", id_token: "x")).to have_http_status(:bad_request)
  end

  it "does not start without a bridge" do
    canonical.post "/auth/apple"
    expect(canonical.response).to have_http_status(:bad_request)
  end
end
