require "rails_helper"
require "webmock/rspec"

RSpec.describe "Sign in with Apple", type: :request do
  let!(:photographer) { create(:photographer, subdomain: "apple") }
  let!(:user) { User.create!(facebook_id: "apple-facebook", name: "Apple tester", email_address: "Tester@Example.com") }
  let(:key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JWT::JWK.new(key, kid: "apple-test-key") }
  let(:nonce) { "raw-nonce-#{SecureRandom.hex(8)}" }

  def identity_token(**claims)
    payload = { iss: "https://appleid.apple.com", aud: "host.lumiere.Chip", sub: "001234.apple-sub",
                iat: Time.current.to_i, exp: 5.minutes.from_now.to_i, nonce: Digest::SHA256.hexdigest(nonce),
                email: "tester@example.com", email_verified: "true", is_private_email: "false" }.merge(claims)
    JWT.encode(payload.compact, key, "RS256", kid: jwk.kid)
  end

  def exchange(token, subdomain: "apple", raw_nonce: nonce)
    post "/auth/apple/exchange", params: { identity_token: token, nonce: raw_nonce, photographer: subdomain }, as: :json
  end

  before do
    host! "api.lumiere.host"
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    stub_request(:get, "https://appleid.apple.com/auth/keys")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { keys: [ jwk.export ] }.to_json)
  end

  it "signs in an admin whose Apple-verified email matches and remembers the Apple ID", :aggregate_failures do
    exchange(identity_token)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["subdomain"]).to eq("apple")
    expect(ServiceAccount.authenticate(response.parsed_body["token"]).user).to eq(user)
    expect(user.reload.apple_sub).to eq("001234.apple-sub")
  end

  it "signs in by the linked Apple ID even with a private relay email" do
    user.update!(apple_sub: "001234.apple-sub")
    exchange(identity_token(email: "abc@privaterelay.appleid.com", is_private_email: "true"))
    expect(response).to have_http_status(:ok)
  end

  it "does not match a private relay or unverified email", :aggregate_failures do
    exchange(identity_token(email: "tester@example.com", email_verified: "false"))
    expect(response).to have_http_status(:forbidden)
    expect(user.reload.apple_sub).to be_nil
  end

  it "does not let a second Apple ID take over a linked account by email" do
    user.update!(apple_sub: "first-apple-id")
    exchange(identity_token(sub: "second-apple-id"))
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses people who don't administer the photographer" do
    create(:photographer, subdomain: "other")
    exchange(identity_token, subdomain: "other")
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses a token issued to another app" do
    exchange(identity_token(aud: "com.example.other"))
    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses a replayed token with the wrong nonce" do
    exchange(identity_token, raw_nonce: "different")
    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses an expired token" do
    exchange(identity_token(iat: 2.hours.ago.to_i, exp: 1.hour.ago.to_i))
    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses a token signed by another key" do
    forged = JWT.encode({ iss: "https://appleid.apple.com", aud: "host.lumiere.Chip", sub: "x", iat: Time.current.to_i,
                          exp: 5.minutes.from_now.to_i, nonce: Digest::SHA256.hexdigest(nonce) },
                        OpenSSL::PKey::RSA.generate(2048), "RS256", kid: jwk.kid)
    exchange(forged)
    expect(response).to have_http_status(:unauthorized)
  end

  it "refuses users being deleted" do
    user.update!(apple_sub: "001234.apple-sub", deletion_pending_at: Time.current)
    exchange(identity_token)
    expect(response).to have_http_status(:forbidden)
  end

  describe "linking an Apple ID from an app session" do
    def bearer
      @bearer ||= ServiceAccount.issue!(photographer: photographer, name: "Chip").then do |account, token|
        account.update!(user: user)
        token
      end
    end

    def link(token, auth: bearer)
      post "/auth/apple/link", params: { identity_token: token, nonce: nonce },
                               headers: { "Authorization" => "Bearer #{auth}" }, as: :json
    end

    it "links a private relay Apple ID so it can sign in later", :aggregate_failures do
      link(identity_token(email: "abc@privaterelay.appleid.com", is_private_email: "true"))
      expect(response).to have_http_status(:no_content)
      expect(user.reload.apple_sub).to eq("001234.apple-sub")
    end

    it "refuses an Apple ID already linked to someone else" do
      User.create!(facebook_id: "someone-else", apple_sub: "001234.apple-sub")
      link(identity_token)
      expect(response).to have_http_status(:conflict)
    end

    it "needs a signed-in app session" do
      link(identity_token, auth: "hbsa_nope")
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
