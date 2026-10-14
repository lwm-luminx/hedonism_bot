require 'rails_helper'

RSpec.describe "Device code sign-in", type: :request do
  let(:photographer) { create(:photographer) }
  let(:source) { ServiceAccount.issue!(photographer: photographer, name: "Provisioner") }
  let(:grant_and_code) { DeviceLoginGrant.issue!(service_account: source.first) }

  before { host! "api.lumiere.host" }

  it "requires a service account to issue a code" do
    post "/auth/device/code"
    expect(response).to have_http_status(:unauthorized)
  end

  it "issues a code with an expiry", :aggregate_failures do
    post "/auth/device/code", headers: { "Authorization" => "Bearer #{source.last}" }
    expect(response.parsed_body["code"]).to match(/\A(?:[0-9A-F]{4}-){4}[0-9A-F]{4}\z/)
    expect(response.headers["Cache-Control"]).to eq("no-store")
  end

  it "exchanges a code for a separate token for the same photographer", :aggregate_failures do
    post "/auth/device/exchange", params: { code: grant_and_code.last.downcase }, as: :json
    account = ServiceAccount.authenticate(response.parsed_body["token"])
    expect(account.photographer).to eq(photographer)
    expect(account).not_to eq(source.first)
  end

  it "rejects a code after it has been used" do
    code = grant_and_code.last
    2.times { post "/auth/device/exchange", params: { code: code }, as: :json }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an expired code" do
    grant_and_code.first.update!(expires_at: 1.minute.ago)
    post "/auth/device/exchange", params: { code: grant_and_code.last }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a code from a revoked service account" do
    code = grant_and_code.last
    source.first.revoke!
    post "/auth/device/exchange", params: { code: code }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
