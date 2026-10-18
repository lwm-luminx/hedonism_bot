require 'rails_helper'
require 'webmock/rspec'

RSpec.describe "Native Facebook sign-in", type: :request do
  let!(:photographer) { create(:photographer, subdomain: "native") }
  let!(:user) { User.create!(facebook_id: "native-facebook", name: "Native tester") }
  let(:verifier) { "v" * 64 }
  let(:challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) }

  before do
    host! "api.lumiere.host"
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(
      provider: "facebook", uid: user.facebook_id, credentials: { token: "facebook-test-token" },
      extra: { raw_info: { "id" => user.facebook_id, "name" => user.name } }
    )
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:facebook] = nil
  end

  # End-to-end protocol verification needs the complete browser/code exchange.
  # rubocop:disable RSpec/ExampleLength
  it "uses the existing Facebook app and returns a proof-bound code", :aggregate_failures do
    get "/auth/native", params: { photographer: "native", challenge: challenge, state: "s" * 32 }
    expect(response).to have_http_status(:ok)
    post "/auth/facebook"
    follow_redirect!
    follow_redirect!
    callback = URI.parse(response.location)
    values = URI.decode_www_form(callback.query).to_h
    expect(callback.scheme).to eq("lumiere-uploader")
    post "/auth/native/exchange", params: { code: values["code"], verifier: verifier }, as: :json
    expect(response.parsed_body["subdomain"]).to eq("native")
    expect(ServiceAccount.authenticate(response.parsed_body["token"]).user).to eq(user)
  end

  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  context "when iOS drops the session cookie while Facebook is on screen" do
    before do
      OmniAuth.config.test_mode = false
      stub_request(:post, %r{\Ahttps://graph\.facebook\.com/.*oauth/access_token})
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: { access_token: "facebook-test-token", token_type: "bearer", expires_in: 3600 }.to_json)
      stub_request(:get, %r{\Ahttps://graph\.facebook\.com/.*me})
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: { id: user.facebook_id, name: user.name }.to_json)
      # The test environment has no Facebook app secret to sign Graph calls with.
      allow_any_instance_of(OmniAuth::Strategies::Facebook).to receive(:appsecret_proof).and_return("proof") # rubocop:disable RSpec/AnyInstance
    end

    # Starts a native sign-in and returns the OAuth state handed to Facebook.
    def start_native_sign_in
      get "/auth/native", params: { photographer: "native", challenge: challenge, state: "s" * 32 }
      post "/auth/facebook"
      Rack::Utils.parse_query(URI.parse(response.location).query).fetch("state")
    end

    it "restores the sign-in from the signed OAuth state", :aggregate_failures do
      state = start_native_sign_in
      cookies.delete("_hedonism_bot_session")
      get "/auth/facebook/callback", params: { code: "facebook-code", state: state }
      expect(response).to redirect_to("/auth/native/complete")
      follow_redirect!
      callback = URI.parse(response.location)
      values = URI.decode_www_form(callback.query).to_h
      expect(callback.scheme).to eq("lumiere-uploader")
      post "/auth/native/exchange", params: { code: values["code"], verifier: verifier }, as: :json
      expect(response.parsed_body["subdomain"]).to eq("native")
    end

    it "returns a cancelled sign-in to the app instead of a 404", :aggregate_failures do
      state = start_native_sign_in
      cookies.delete("_hedonism_bot_session")
      get "/auth/facebook/callback", params: { error: "access_denied", error_reason: "user_denied", state: state }
      follow_redirect!
      callback = URI.parse(response.location)
      expect(callback.scheme).to eq("lumiere-uploader")
      expect(URI.decode_www_form(callback.query).to_h).to include("state" => "s" * 32, "error" => "no_authorization_code")
    end

    it "still rejects a forged state" do
      start_native_sign_in
      cookies.delete("_hedonism_bot_session")
      get "/auth/facebook/callback", params: { code: "facebook-code", state: "forged" }
      expect(response.location).to include("/auth/failure?message=")
    end
  end
  # rubocop:enable RSpec/ExampleLength

  it "rejects malformed authorization requests" do
    get "/auth/native", params: { photographer: "native", challenge: "bad", state: "bad" }
    expect(response).to have_http_status(:bad_request)
  end

  # Exercise production CSRF behavior while restoring the global test setting.
  # rubocop:disable RSpec/ExampleLength
  it "exchanges a PKCE grant without browser CSRF credentials" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    NativeLoginGrant.create!(code_digest: Digest::SHA256.hexdigest("mobile-code"), challenge: challenge,
                            user: user, photographer: photographer, expires_at: 2.minutes.from_now)
    post "/auth/native/exchange", params: { code: "mobile-code", verifier: verifier }, as: :json
    expect(response).to have_http_status(:ok)
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
  # rubocop:enable RSpec/ExampleLength
end
