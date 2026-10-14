require 'rails_helper'

RSpec.describe "Archive storage registration", type: :request do
  let!(:photographer) { create(:photographer, subdomain: "storage") }
  let!(:user) { User.create!(facebook_id: "storage-admin", name: "Storage admin") }
  let(:account) { ServiceAccount.issue!(photographer: photographer, name: "Cogsworth") }
  let(:headers) { { "Authorization" => "Bearer #{account.last}" } }

  before do
    host! "storage.lumiere.host"
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

  def register(paths = [ "/Volumes/Archive", "/Users/test/Archive" ])
    put "/auth/archive_storage", params: { device_name: "Studio Mac", paths: paths }, headers: headers, as: :json
  end

  it "rejects registration without a bearer token" do
    put "/auth/archive_storage", params: { device_name: "Mac", paths: [] }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "stores multiple paths on the authenticated account" do
    register
    expect(ArchiveStorageConnection.last).to have_attributes(service_account: account.first, paths: [ "/Volumes/Archive", "/Users/test/Archive" ])
  end

  it "updates the existing connection on heartbeat" do
    register
    expect { register([]) }.not_to change(ArchiveStorageConnection, :count)
  end

  it "rejects relative paths" do
    register([ "../archive" ])
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects revoked credentials" do
    account.first.revoke!
    register
    expect(response).to have_http_status(:unauthorized)
  end

  it "requires admin access to list connections" do
    sign_in
    get "/admin/archive_storage_connections"
    expect(response).to have_http_status(:forbidden)
  end

  def sign_in_as_admin
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    sign_in
  end

  def register_other_photographer
    other, = ServiceAccount.issue!(photographer: create(:photographer), name: "Other Mac")
    ArchiveStorageConnection.create!(service_account: other, device_name: "Other", paths: [ "/private" ], last_seen_at: Time.current)
  end

  it "only lists connections belonging to this photographer" do
    register
    register_other_photographer
    sign_in_as_admin
    get "/admin/archive_storage_connections"
    expect(response.parsed_body["connections"].pluck("device_name")).to eq([ "Studio Mac" ])
  end
end
