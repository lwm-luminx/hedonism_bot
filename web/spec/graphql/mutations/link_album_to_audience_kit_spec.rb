require "rails_helper"

# Each scenario checks the authorization and the result together.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
RSpec.describe Mutations::LinkAlbumToAudienceKit, type: :graphql do
  let(:photographer) { create(:photographer) }
  let(:audience_id) { SecureRandom.uuid }
  let(:event_id) { SecureRandom.uuid }
  let(:venue_id) { SecureRandom.uuid }
  let(:album) { Album.create!(photographer: photographer, name: "Drag Bingo") }
  let(:client) { instance_double(AudienceKit::Client) }
  let(:catalog) do
    { "audiences" => [ { "id" => audience_id, "name" => "Hot Mess",
                         "events" => [ { "id" => event_id, "name" => "Drag Bingo", "startAt" => "2026-10-24T03:00:00Z", "venueId" => venue_id } ],
                         "venues" => [ { "id" => venue_id, "name" => "Stonewall Inn" } ] } ] }
  end
  let(:link) do
    <<~GQL
      mutation($folder: ID!, $audience: ID!, $event: ID, $venue: ID) {
        linkAlbumToAudienceKit(folderId: $folder, audienceId: $audience, eventId: $event, venueId: $venue) {
          folder { audienceKitLinks { audienceId audienceName venueId venueName eventId eventName eventStartAt } }
        }
      }
    GQL
  end
  let(:catalog_query) { "{ audienceKitCatalog(query: \"bingo\") { id name events { id name venueId } venues { id name } } }" }

  before do
    allow(AudienceKit::Client).to receive(:new).and_return(client)
    allow(client).to receive(:catalog).and_return(catalog)
    PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id)
  end

  def run(variables)
    execute_graphql(link, variables: { folder: album.to_gid_param, audience: audience_id, **variables },
                          context: uploader_context(photographer))
  end

  it "links the album to the event and its venue, as AudienceKit names them" do
    run(event: event_id)

    expect(response_errors).to be_nil
    expect(data.dig("linkAlbumToAudienceKit", "folder", "audienceKitLinks")).to eq [
      { "audienceId" => audience_id, "audienceName" => "Hot Mess", "venueId" => venue_id, "venueName" => "Stonewall Inn",
        "eventId" => event_id, "eventName" => "Drag Bingo", "eventStartAt" => "2026-10-24T03:00:00Z" }
    ]
    expect(client).to have_received(:catalog).with(photographer.id, audience_id: audience_id, event_id: event_id, venue_id: nil)
  end

  it "replaces the audience's link with a venue-only one" do
    run(event: event_id)
    run(venue: venue_id)

    expect(album.album_events.sole).to have_attributes(audience_kit_venue_id: venue_id, audience_kit_event_id: nil)
  end

  it "refuses what AudienceKit doesn't list" do
    run(event: SecureRandom.uuid)

    expect(response_errors.first["message"]).to eq "That event isn't one this photographer can link to"
    expect(album.album_events).to be_empty
  end

  it "refuses an audience without a live grant here, whatever AudienceKit lists" do
    PhotographyGrant.update_all(revoked_at: Time.current)
    run(event: event_id)

    expect(response_errors.first["message"]).to eq "That audience isn't connected to this photographer"
  end

  it "needs an uploader" do
    execute_graphql(link, variables: { folder: album.to_gid_param, audience: audience_id, event: event_id },
                          context: { photographer: photographer })

    expect(response_errors.first["message"]).to eq "Admin sign-in required"
  end

  it "lists the catalog for granted audiences only, and reports AudienceKit failing" do
    other = catalog["audiences"].first.merge("id" => SecureRandom.uuid, "name" => "Elsewhere")
    allow(client).to receive(:catalog).and_return("audiences" => catalog["audiences"] + [ other ])
    execute_graphql(catalog_query, context: uploader_context(photographer))
    expect(data["audienceKitCatalog"].pluck("name")).to eq [ "Hot Mess" ]

    allow(client).to receive(:catalog).and_raise(AudienceKit::Client::NotConfigured, "AudienceKit isn't connected")
    execute_graphql(catalog_query, context: uploader_context(photographer))
    expect(response_errors.first["message"]).to eq "AudienceKit isn't connected"
  end

  it "unlinks" do
    run(event: event_id)
    execute_graphql(<<~GQL, variables: { folder: album.to_gid_param, audience: audience_id }, context: uploader_context(photographer))
      mutation($folder: ID!, $audience: ID!) {
        unlinkAlbumFromAudienceKit(folderId: $folder, audienceId: $audience) { folder { audienceKitLinks { audienceId } } }
      }
    GQL

    expect(data.dig("unlinkAlbumFromAudienceKit", "folder", "audienceKitLinks")).to eq []
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
