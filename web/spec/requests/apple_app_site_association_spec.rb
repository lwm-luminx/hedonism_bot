require "rails_helper"

RSpec.describe "Apple app site association", type: :request do
  let(:apps) { %w[Chip ChipMac Cogsworth].map { |name| "DWVXMLB45Y.host.lumiere.#{name}" } }

  it "lists the Lumière apps as web credential partners", :aggregate_failures do
    host! "api.lumiere.host"
    get "/.well-known/apple-app-site-association"
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body.dig("webcredentials", "apps")).to match_array(apps)
  end
end
