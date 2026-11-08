require "rails_helper"

# Both halves of the AudienceKit integration in one story: the photographer links an album through the admin GraphQL
# API (which reads AudienceKit's catalog), and AudienceKit's next incremental pull over the photography contract sees
# the venue and event on the album's published photos, then sees them change and go when the link does.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
RSpec.describe "AudienceKit round trip", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "round-trip", active: true) }
  let(:album) { Album.create!(photographer: photographer, name: "Drag Bingo") }
  let(:audience_id) { SecureRandom.uuid }
  let(:event_id) { SecureRandom.uuid }
  let(:venue_id) { SecureRandom.uuid }
  let(:patio_id) { SecureRandom.uuid }
  let(:issued) { PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id) }
  let(:client) { instance_double(AudienceKit::Client) }
  let(:photo) do
    Photo.create!(album: album).tap do |photo|
      PhotoTake.create!(photo: photo, status: "processed", original_filename: "a.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    end
  end

  before do
    allow(AudienceKit::Client).to receive(:new).and_return(client)
    allow(client).to receive(:catalog).and_return(
      "audiences" => [ { "id" => audience_id, "name" => "Hot Mess",
                         "events" => [ { "id" => event_id, "name" => "Drag Bingo", "startAt" => "2026-10-24T03:00:00Z",
                                         "venueId" => venue_id } ],
                         "venues" => [ { "id" => venue_id, "name" => "Stonewall Inn" }, { "id" => patio_id, "name" => "Patio" } ] } ]
    )
    issued.first.publish!(photo)
  end

  def admin(query, **variables)
    result = HedonismBotSchema.execute(query, variables: { folder: album.to_gid_param, audience: audience_id, **variables },
                                              context: { photographer: photographer, service_account: true })
    expect(result["errors"]).to be_nil
    result["data"]
  end

  def link(**variables)
    admin(<<~GQL, **variables)
      mutation($folder: ID!, $audience: ID!, $event: ID, $venue: ID) {
        linkAlbumToAudienceKit(folderId: $folder, audienceId: $audience, eventId: $event, venueId: $venue) { link { venueId } }
      }
    GQL
  end

  def unlink
    admin(<<~GQL)
      mutation($folder: ID!, $audience: ID!) {
        unlinkAlbumFromAudienceKit(folderId: $folder, audienceId: $audience) { folder { audienceKitLinks { audienceId } } }
      }
    GQL
  end

  # What AudienceKit's pull since `since` returns, as it calls the contract.
  def pull(since)
    travel 1.second
    post "/extensions/photography/graphql", as: :json, params: {
      query: "query($audience: ID!, $since: ISO8601DateTime) { photographer(audienceId: $audience) " \
             "{ photos(first: 10, updatedSince: $since) { nodes { id removed venueId eventId } } } }",
      variables: { audience: audience_id, since: since.iso8601(6) }, extensions: { accessToken: issued.last }
    }
    expect(response.parsed_body["errors"]).to be_nil
    response.parsed_body.dig("data", "photographer", "photos", "nodes")
  end

  it "carries each link change to AudienceKit's next incremental pull" do
    travel 1.minute
    since = Time.current
    expect(pull(since)).to eq []

    since = Time.current
    link(event: event_id)
    expect(pull(since)).to eq [ { "id" => photo.id, "removed" => false, "venueId" => venue_id, "eventId" => event_id } ]

    since = Time.current
    expect(pull(since)).to eq []

    link(venue: patio_id)
    expect(pull(since)).to eq [ { "id" => photo.id, "removed" => false, "venueId" => patio_id, "eventId" => nil } ]

    since = Time.current
    unlink
    expect(pull(since)).to eq [ { "id" => photo.id, "removed" => false, "venueId" => nil, "eventId" => nil } ]
  end

  it "keeps a link in another audience out of this audience's pull" do
    other_audience = SecureRandom.uuid
    PhotographyGrant.issue!(photographer: photographer, audience_id: other_audience)
    allow(client).to receive(:catalog).and_return(
      "audiences" => [ { "id" => other_audience, "name" => "Elsewhere", "events" => [], "venues" => [ { "id" => patio_id, "name" => "Patio" } ] } ]
    )

    travel 1.minute
    since = Time.current
    link(audience: other_audience, venue: patio_id)
    expect(pull(since)).to eq []
    expect(pull(1.day.ago)).to eq [ { "id" => photo.id, "removed" => false, "venueId" => nil, "eventId" => nil } ]
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
