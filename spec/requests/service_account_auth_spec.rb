require 'rails_helper'

RSpec.describe "Service account auth", type: :request do
  let(:photographer) { Photographer.create!(name: "Rick", subdomain: "rick") }
  let(:token) { ServiceAccount.issue!(photographer: photographer, name: "Mac").last }
  let(:query) { "{ photographer { subdomain } }" }

  before { host! "api.lumiere.host" }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  it "acts as the token's photographer" do
    post "/graphql", params: { query: query }, headers: { "Authorization" => "Bearer #{token}" }

    expect(response.parsed_body.dig("data", "photographer", "subdomain")).to eq("rick")
  end

  it "rejects an unknown token" do
    post "/graphql", params: { query: query }, headers: { "Authorization" => "Bearer hbsa_nope" }

    expect(response).to have_http_status(:unauthorized)
  end
end
