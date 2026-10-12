require "rails_helper"

# Request scenarios verify authorization and the response together.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe "Photography provider", type: :request do
  let(:audience_id) { SecureRandom.uuid }
  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "photo-contract", active: true) }
  let(:issued) { PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id) }
  let(:grant) { issued.first }
  let(:token) { issued.last }

  it "publishes service metadata without granting anonymous photo access" do
    allow(IntegrationMetadata).to receive(:details).and_return(
      website_url: "https://photos.example", company_name: "Example Company",
      support_url: "https://photos.example/help", support_email: "help@photos.example"
    )
    metadata = { query: "{ integrationMetadata { websiteUrl companyName supportUrl supportEmail } }",
                 variables: {}, extensions: {} }
    post "/extensions/photography/graphql", params: [ metadata, operation("invalid") ], as: :json
    expect(response.parsed_body.first.dig("data", "integrationMetadata")).to eq(
      "websiteUrl" => "https://photos.example", "companyName" => "Example Company",
      "supportUrl" => "https://photos.example/help", "supportEmail" => "help@photos.example"
    )
    expect(response.parsed_body.last.dig("data", "photographer")).to be_nil
    expect(response.parsed_body.last["errors"]).to be_present
  end

  def query
    'query($audience: ID!, $after: String, $since: ISO8601DateTime, $first: Int = 1) { contractVersion ' \
      'photographer(audienceId: $audience) { id name grantExpiresAt photos(first: $first, after: $after, updatedSince: $since) ' \
      '{ nodes { id takeCount previewUrl removed } pageInfo { endCursor hasNextPage } } } }'
  end

  def operation(access_token = token, audience = audience_id, **variables)
    { query: query, variables: { audience: audience, **variables }, extensions: { accessToken: access_token } }
  end

  def nodes
    response.parsed_body.dig("data", "photographer", "photos", "nodes")
  end

  def make_photo(owner = photographer, status: "processed")
    album = Album.create!(photographer: owner, name: "Shared")
    photo = Photo.create!(album: album)
    PhotoTake.create!(photo: photo, status: status, original_filename: "test.jpg", content_type: "image/jpeg", file_size_bytes: 10)
    photo
  end

  it "serves only explicitly shared logical photos, keeping pending and unshared photos private" do
    shared = make_photo
    make_photo
    pending = make_photo(status: "pending")
    grant.photography_publications.create!(photo: shared)
    grant.photography_publications.create!(photo: pending)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["errors"]).to be_nil
    expect(nodes).to eq [ { "id" => shared.id, "takeCount" => 1, "previewUrl" => nil, "removed" => false } ]
  end

  it "serves the contract version and the grant's expiry" do
    grant.update!(expires_at: 1.day.from_now)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(response.parsed_body.dig("data", "contractVersion")).to eq Photography::QueryType::CONTRACT_VERSION
    expect(response.parsed_body.dig("data", "photographer", "grantExpiresAt")).to eq grant.expires_at.utc.iso8601
  end

  it "rejects expired grants" do
    grant.update!(expires_at: 1.minute.ago)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(response.parsed_body.dig("data", "photographer")).to be_nil
    expect(response.parsed_body["errors"]).to be_present
  end

  it "matches the audience id case-insensitively" do
    post "/extensions/photography/graphql", params: operation(token, audience_id.upcase), as: :json
    expect(response.parsed_body["errors"]).to be_nil
    expect(response.parsed_body.dig("data", "photographer", "id")).to eq photographer.id
  end

  it "links previews through the photographer's stable /previews route" do
    shared = make_photo
    shared.processed_takes.first.images.attach(io: Rails.root.join("spec/fixtures/test.jpg").open, filename: "test.jpg", content_type: "image/jpeg")
    grant.publish!(shared)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(nodes.first["previewUrl"]).to eq "https://photo-contract.lumiere.host/previews/#{shared.processed_takes.first.id}"
  end

  it "authenticates each batched operation independently" do
    post "/extensions/photography/graphql", params: [ operation, operation("invalid") ], as: :json
    expect(response.parsed_body.first.dig("data", "photographer", "id")).to eq photographer.id
    expect(response.parsed_body.last.dig("data", "photographer")).to be_nil
    expect(response.parsed_body.last["errors"]).to be_present
  end

  it "rejects a valid credential used for another audience" do
    post "/extensions/photography/graphql", params: operation(token, SecureRandom.uuid), as: :json
    expect(response.parsed_body.dig("data", "photographer")).to be_nil
    expect(response.parsed_body["errors"]).to be_present
  end

  it "rejects revoked grants" do
    grant.update!(revoked_at: Time.current)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(response.parsed_body.dig("data", "photographer")).to be_nil
  end

  it "keeps different photographers isolated in the same batch" do
    other = Photographer.create!(name: "Alex", subdomain: "photo-contract-alex", active: true)
    _other_grant, other_token = PhotographyGrant.issue!(photographer: other, audience_id: audience_id)
    post "/extensions/photography/graphql", params: [ operation, operation(other_token) ], as: :json
    expect(response.parsed_body.map { |result| result.dig("data", "photographer", "id") }).to eq [ photographer.id, other.id ]
  end

  it "excludes photos moved out of the photographer after publication" do
    shared = make_photo
    grant.photography_publications.create!(photo: shared)
    other = Photographer.create!(name: "Other", subdomain: "photo-moved", active: true)
    shared.album.update!(photographer: other)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(response.parsed_body.dig("data", "photographer", "photos", "nodes")).to eq []
  end

  it "paginates logical photos by keyset cursor on (publishedAt, id), oldest publication first" do
    first, second = 2.times.map { make_photo }
    grant.publish!(first)
    travel 1.minute
    grant.publish!(second)
    post "/extensions/photography/graphql", params: operation, as: :json
    page = response.parsed_body.dig("data", "photographer", "photos")
    expect(page.fetch("nodes").pluck("id")).to eq [ first.id ]
    expect(page.fetch("pageInfo")).to include("hasNextPage" => true, "endCursor" => be_present)
    post "/extensions/photography/graphql", params: operation(after: page.dig("pageInfo", "endCursor")), as: :json
    page = response.parsed_body.dig("data", "photographer", "photos")
    expect(page.fetch("nodes").pluck("id")).to eq [ second.id ]
    expect(page.fetch("pageInfo")).to include("hasNextPage" => false)
  end

  it "keeps the cursor valid when a photo is removed behind it" do
    first, second, third = 3.times.map { make_photo }
    [ first, second, third ].each { |photo| grant.publish!(photo) && travel(1.minute) }
    post "/extensions/photography/graphql", params: operation, as: :json
    cursor = response.parsed_body.dig("data", "photographer", "photos", "pageInfo", "endCursor")
    grant.unpublish!(first)
    post "/extensions/photography/graphql", params: operation(after: cursor), as: :json
    expect(nodes.pluck("id")).to eq [ second.id ]
  end

  it "rejects a cursor it did not issue" do
    post "/extensions/photography/graphql", params: operation(after: "not-a-cursor"), as: :json
    # Every connection field (nodes, pageInfo) reports the bad cursor; the message is the same for each.
    expect(response.parsed_body["errors"].pluck("message").uniq).to eq [ "Invalid photo cursor" ]
  end

  it "lists unpublished and deleted photos as tombstones for updatedSince, and hides them otherwise" do
    kept, unpublished, deleted = 3.times.map { make_photo }
    [ kept, unpublished, deleted ].each { |photo| grant.publish!(photo) }
    travel 1.hour
    since = Time.current
    grant.unpublish!(unpublished)
    deleted_id = deleted.id
    deleted.photo_takes.destroy_all
    deleted.destroy!

    post "/extensions/photography/graphql", params: operation(since: since.iso8601, first: 10), as: :json
    expect(response.parsed_body["errors"]).to be_nil
    expect(nodes).to contain_exactly(
      { "id" => unpublished.id, "takeCount" => 0, "previewUrl" => nil, "removed" => true },
      { "id" => deleted_id, "takeCount" => 0, "previewUrl" => nil, "removed" => true }
    )
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(nodes.pluck("id")).to eq [ kept.id ]
  end

  it "shares a photo again after it was unpublished" do
    photo = make_photo
    grant.publish!(photo)
    grant.unpublish!(photo)
    grant.publish!(photo)
    post "/extensions/photography/graphql", params: operation, as: :json
    expect(nodes).to eq [ { "id" => photo.id, "takeCount" => 1, "previewUrl" => nil, "removed" => false } ]
    expect(grant.photography_publications.count).to eq 1
  end

  it "rejects publications from a different photographer" do
    other = Photographer.create!(name: "Other", subdomain: "photo-contract-other", active: true)
    publication = grant.photography_publications.build(photo: make_photo(other))
    expect(publication).not_to be_valid
  end

  it "bounds batches and exposes no mutation root" do
    post "/extensions/photography/graphql", params: Array.new(21) { operation }, as: :json
    expect(response).to have_http_status(:bad_request)
    expect(Photography::Schema.mutation).to be_nil
  end
end

# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
