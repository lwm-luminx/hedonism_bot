require 'rails_helper'

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

  it "rejects malformed authorization requests" do
    get "/auth/native", params: { photographer: "native", challenge: "bad", state: "bad" }
    expect(response).to have_http_status(:bad_request)
  end
end
