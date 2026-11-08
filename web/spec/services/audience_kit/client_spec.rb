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

  it "exchanges ahead of the JWT's expiry rather than sending one about to lapse" do
    stub_request(:post, "https://api.audiencekit.test/v1/token/service")
      .to_return({ status: 200, body: { token: "jwt-short", expiresAt: 2.minutes.from_now.utc.iso8601 }.to_json },
                 { status: 200, body: { token: "jwt-2", expiresAt: 1.hour.from_now.utc.iso8601 }.to_json })
    stub_request(:get, catalog_url).to_return(status: 200, body: catalog.to_json)

    expect(described_class.bearer).to eq "jwt-short"
    expect(described_class.bearer).to eq "jwt-2"
    expect(described_class.bearer).to eq "jwt-2"
    expect(a_request(:post, "https://api.audiencekit.test/v1/token/service")).to have_been_made.twice
  end

  it "gives up after one fresh exchange when AudienceKit keeps turning the JWT away" do
    stub_exchange
    read = stub_request(:get, catalog_url).to_return(status: 401, body: { message: "Invalid token" }.to_json)

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, /401: Invalid token/)
    expect(read).to have_been_requested.twice
  end

  it "sends the filters AudienceKit understands, times in UTC, and leaves out blank ones" do
    stub_exchange
    from = Time.zone.parse("2026-10-24 20:00:00 -0700")
    read = stub_request(:get, catalog_url)
           .with(query: { "audience_id" => "aud", "from" => "2026-10-25T03:00:00Z", "latitude" => "40.7", "longitude" => "-74.0",
                          "event_id" => "ev" })
           .to_return(status: 200, body: catalog.to_json)

    described_class.new.catalog(photographer_id, audience_id: "aud", from: from, query: "", latitude: 40.7, longitude: -74.0,
                                                 event_id: "ev")
    expect(read).to have_been_requested
  end

  it "escapes the photographer id into the path" do
    stub_exchange
    read = stub_request(:get, "https://api.audiencekit.test/v1/platform/photographers/a%2Fb%3Fc/catalog")
           .to_return(status: 200, body: catalog.to_json)

    described_class.new.catalog("a/b?c")
    expect(read).to have_been_requested
  end

  it "reports a catalog without an audiences list" do
    stub_exchange
    stub_request(:get, catalog_url).to_return(status: 200, body: { "venues" => [] }.to_json)

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, "AudienceKit sent a malformed catalog")
  end

  it "reports an answer that isn't JSON" do
    stub_exchange
    stub_request(:get, catalog_url).to_return(status: 200, body: "<html>maintenance</html>")

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, "AudienceKit sent something that isn't JSON")
  end

  it "reports a refusal whose body isn't JSON by its status" do
    stub_exchange
    stub_request(:get, catalog_url).to_return(status: [ 502, "Bad Gateway" ], body: "<html>")

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, /502: Bad Gateway/)
  end

  it "reports AudienceKit being unreachable" do
    stub_exchange
    stub_request(:get, catalog_url).to_timeout

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, /couldn't be reached/)

    stub_request(:get, catalog_url).to_raise(Errno::ECONNREFUSED)
    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, /couldn't be reached/)
  end

  it "reports a token exchange that answers without a token, and keeps no JWT" do
    stub_request(:post, "https://api.audiencekit.test/v1/token/service").to_return(status: 200, body: { ok: true }.to_json)

    expect { described_class.new.catalog(photographer_id) }
      .to raise_error(described_class::Error, "AudienceKit answered the token exchange without a token")
    expect(described_class.jwt).to be_nil
  end

  it "reports a refused service token" do
    stub_request(:post, "https://api.audiencekit.test/v1/token/service")
      .to_return(status: 401, body: { message: "Unknown service token" }.to_json)

    expect { described_class.new.catalog(photographer_id) }.to raise_error(described_class::Error, /401: Unknown service token/)
    expect(a_request(:post, "https://api.audiencekit.test/v1/token/service")).to have_been_made.once
  end

  it "talks to api.audiencekit.com unless told otherwise" do
    ENV.delete("AUDIENCEKIT_API_URL")
    expect(described_class.base_url).to eq "https://api.audiencekit.com"

    ENV["AUDIENCEKIT_API_URL"] = "https://staging.audiencekit.test/"
    expect(described_class.base_url).to eq "https://staging.audiencekit.test"
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
