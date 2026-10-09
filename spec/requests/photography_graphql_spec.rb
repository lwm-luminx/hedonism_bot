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
    'query($audience: ID!) { contractVersion photographer(audienceId: $audience) { id name photos(first: 1) ' \
      '{ nodes { id takeCount previewUrl } pageInfo { endCursor hasNextPage } } } }'
  end

  def operation(access_token = token, audience = audience_id)
    { query: query, variables: { audience: audience }, extensions: { accessToken: access_token } }
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
    expect(response.parsed_body.dig("data", "photographer", "photos", "nodes")).to eq [
      { "id" => shared.id, "takeCount" => 1, "previewUrl" => nil }
    ]
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

  it "paginates logical photos with a provider cursor" do
    2.times { grant.photography_publications.create!(photo: make_photo) }
    post "/extensions/photography/graphql", params: operation, as: :json
    page = response.parsed_body.dig("data", "photographer", "photos")
    expect(page.fetch("nodes").length).to eq 1
    expect(page.fetch("pageInfo")).to include("hasNextPage" => true, "endCursor" => be_present)
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
