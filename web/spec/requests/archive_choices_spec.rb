require "rails_helper"
require "webmock/rspec"

RSpec.describe "Choosing an archive after signing in", type: :request do
  let!(:luminx) { create(:photographer, subdomain: "luminx", name: "Luminx") }
  let(:lovewins) { Photographer.find_by!(subdomain: "lovewins") }
  let!(:user) { User.create!(facebook_id: "chooser", name: "Chooser", apple_sub: "001234.chooser") }
  let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "archive-choice-key") }
  let(:nonce) { "raw-nonce-#{SecureRandom.hex(8)}" }

  def identity_token
    payload = { iss: "https://appleid.apple.com", aud: "host.lumiere.Chip", sub: "001234.chooser",
                iat: Time.current.to_i, exp: 5.minutes.from_now.to_i, nonce: Digest::SHA256.hexdigest(nonce) }
    JWT.encode(payload, jwk.signing_key, "RS256", kid: jwk.kid)
  end

  def apple_sign_in
    post "/auth/apple/exchange", params: { identity_token: identity_token, nonce: nonce }, as: :json
    response.parsed_body
  end

  def select(selection, subdomain)
    post "/auth/archives/select", params: { selection: selection, photographer: subdomain }, as: :json
  end

  before do
    create(:photographer, subdomain: "lovewins", name: "Love Wins")
    host! "api.lumiere.host"
    stub_request(:get, "https://appleid.apple.com/auth/keys")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { keys: [ jwk.export ] }.to_json)
  end

  it "signs straight in to a person's only archive", :aggregate_failures do
    PhotographerAdmin.create!(user: user, photographer: luminx, role: "admin")
    body = apple_sign_in
    expect(body["subdomain"]).to eq("luminx")
    expect(ServiceAccount.authenticate(body["token"])).to have_attributes(user: user, photographer: luminx)
  end

  context "when the person administers several archives" do
    before do
      PhotographerAdmin.create!(user: user, photographer: luminx, role: "admin")
      PhotographerAdmin.create!(user: user, photographer: lovewins, role: "admin")
    end

    it "lists them by name instead of issuing a credential", :aggregate_failures do
      body = apple_sign_in
      expect(body).not_to have_key("token")
      expect(body["photographers"]).to eq([ { "subdomain" => "lovewins", "name" => "Love Wins" },
                                            { "subdomain" => "luminx", "name" => "Luminx" } ])
    end

    it "issues a credential for the archive picked", :aggregate_failures do
      select(apple_sign_in["selection"], "lovewins")
      expect(response).to have_http_status(:ok)
      expect(ServiceAccount.authenticate(response.parsed_body["token"])).to have_attributes(user: user, photographer: lovewins)
    end

    it "refuses an archive the person doesn't administer" do
      create(:photographer, subdomain: "stranger")
      select(apple_sign_in["selection"], "stranger")
      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses an expired selection" do
      selection = apple_sign_in["selection"]
      travel 11.minutes do
        select(selection, "luminx")
      end
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "refuses a forged selection" do
    select("forged", "luminx")
    expect(response).to have_http_status(:unauthorized)
  end

  it "explains when the person administers no archive", :aggregate_failures do
    apple_sign_in
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body["error"]).to eq(ArchiveChoice::NO_ARCHIVES)
  end

  describe "Facebook sign-in from the apps without an archive" do
    def verifier = "v" * 64

    before do
      PhotographerAdmin.create!(user: user, photographer: luminx, role: "admin")
      PhotographerAdmin.create!(user: user, photographer: lovewins, role: "admin")
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

    def facebook_code
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
      get "/auth/native", params: { challenge: challenge, state: "s" * 32 }
      post "/auth/facebook"
      follow_redirect!
      follow_redirect!
      URI.decode_www_form(URI.parse(response.location).query).to_h["code"]
    end

    it "returns the archives to choose from", :aggregate_failures do
      post "/auth/native/exchange", params: { code: facebook_code, verifier: verifier }, as: :json
      expect(response.parsed_body["photographers"].pluck("subdomain")).to eq(%w[lovewins luminx])
      select(response.parsed_body["selection"], "luminx")
      expect(response.parsed_body["subdomain"]).to eq("luminx")
    end

    it "still rejects an unknown archive name from older apps" do
      get "/auth/native", params: { photographer: "nope", challenge: "c" * 43, state: "s" * 32 }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
