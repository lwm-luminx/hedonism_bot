require "rails_helper"
require "webmock/rspec"

# Each scenario checks what is sent to AudienceKit and what comes back together.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe AudienceKit::Client do
  let(:photographer_id) { SecureRandom.uuid }
  let(:catalog_url) { %r{\Ahttps://api\.audiencekit\.test/v1/platform/photographers/#{photographer_id}/catalog} }
  let(:catalog) { { "audiences" => [ { "id" => SecureRandom.uuid, "name" => "Hot Mess", "events" => [], "venues" => [] } ] } }

  around do |example|
    env = { "AUDIENCEKIT_SERVICE_TOKEN" => "akst_prefix_secret", "AUDIENCEKIT_API_URL" => "https://api.audiencekit.test" }
    previous = env.keys.index_with { |key| ENV[key] }
    env.each { |key, value| ENV[key] = value }
    described_class.reset!
    example.run
  ensure
    previous.each { |key, value| ENV[key] = value }
    described_class.reset!
  end

  def stub_exchange(token = "jwt-1")
    stub_request(:post, "https://api.audiencekit.test/v1/token/service")
      .with(body: { service_token: "akst_prefix_secret" })
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { token: token, expiresAt: 1.hour.from_now.utc.iso8601 }.to_json)
  end

  it "exchanges the service token once and reads the catalog with the JWT" do
    exchange = stub_exchange
    read = stub_request(:get, catalog_url).with(headers: { "Authorization" => "Bearer jwt-1" }, query: hash_including("query" => "bingo"))
                                          .to_return(status: 200, body: catalog.to_json)

    client = described_class.new
    2.times { expect(client.catalog(photographer_id, query: "bingo")).to eq catalog }
    expect(exchange).to have_been_requested.once
    expect(read).to have_been_requested.twice
  end

  it "exchanges again when AudienceKit turns the JWT away" do
    stub_exchange
    stub_request(:get, catalog_url).to_return({ status: 401, body: { message: "expired" }.to_json },
                                              { status: 200, body: catalog.to_json })

    expect(described_class.new.catalog(photographer_id)).to eq catalog
    expect(a_request(:post, "https://api.audiencekit.test/v1/token/service")).to have_been_made.twice
  end

  it "reports AudienceKit's refusal" do
    stub_exchange
    stub_request(:get, catalog_url).to_return(status: 403, body: { message: "This needs a platform service token" }.to_json)

    expect { described_class.new.catalog(photographer_id) }
      .to raise_error(described_class::Error, /403: This needs a platform service token/)
  end

  it "needs the service token" do
    ENV.delete("AUDIENCEKIT_SERVICE_TOKEN")

    expect(described_class).not_to be_configured
    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::NotConfigured)
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
