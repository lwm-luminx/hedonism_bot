require "rails_helper"

# What a photographer may link albums to: AudienceKit's catalog narrowed to the audiences holding a live grant here.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
RSpec.describe AudienceKitCatalog do
  subject(:catalog) { described_class.new(photographer, client: client) }

  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "catalog-sam", active: true) }
  let(:album) { Album.create!(photographer: photographer, name: "Drag Bingo") }
  let(:client) { instance_double(AudienceKit::Client) }
  let(:audience_id) { SecureRandom.uuid }
  let(:event_id) { SecureRandom.uuid }
  let(:venue_id) { SecureRandom.uuid }
  let(:other_venue_id) { SecureRandom.uuid }
  let(:listing) do
    { "audiences" => [ { "id" => audience_id.upcase, "name" => "Hot Mess",
                         "events" => [ { "id" => event_id, "name" => "Drag Bingo", "startAt" => "2026-10-24T03:00:00Z",
                                         "venueId" => venue_id } ],
                         "venues" => [ { "id" => venue_id, "name" => "Stonewall Inn" },
                                       { "id" => other_venue_id, "name" => "Julius'" } ] } ] }
  end

  before { allow(client).to receive(:catalog).and_return(listing) }

  describe "#audiences" do
    it "doesn't ask AudienceKit when the photographer has no live grant" do
      expect(catalog.audiences).to eq []
      expect(client).not_to have_received(:catalog)
    end

    it "matches granted audiences case-insensitively and passes the filters through" do
      PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id)

      expect(catalog.audiences(query: "bingo").pluck("name")).to eq [ "Hot Mess" ]
      expect(client).to have_received(:catalog).with(photographer.id, query: "bingo")
    end

    it "leaves out audiences whose grant expired or was revoked" do
      PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id, expires_at: 1.minute.ago)
      expect(catalog.audiences).to eq []

      grant, = PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id)
      expect(catalog.audiences.size).to eq 1
      grant.update!(revoked_at: Time.current)
      expect(catalog.audiences).to eq []
    end

    it "ignores grants of other photographers and entries that aren't audiences" do
      other = Photographer.create!(name: "Other", subdomain: "catalog-other", active: true)
      PhotographyGrant.issue!(photographer: other, audience_id: audience_id)
      expect(catalog.audiences).to eq []

      PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id)
      allow(client).to receive(:catalog).and_return("audiences" => [ "junk", nil, *listing["audiences"] ])
      expect(catalog.audiences.pluck("name")).to eq [ "Hot Mess" ]
    end
  end

  describe "#link!" do
    before { PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id) }

    it "takes the event's venue, whatever venue is also passed" do
      link = catalog.link!(album, audience_id: audience_id, event_id: event_id.upcase, venue_id: other_venue_id)

      expect(link).to have_attributes(audience_id: audience_id, audience_name: "Hot Mess", audience_kit_venue_id: venue_id,
                                      venue_name: "Stonewall Inn", audience_kit_event_id: event_id, event_name: "Drag Bingo")
      expect(link.event_start_at).to eq Time.iso8601("2026-10-24T03:00:00Z")
    end

    it "links a venue with no event" do
      link = catalog.link!(album, audience_id: audience_id, venue_id: other_venue_id)

      expect(link).to have_attributes(audience_kit_venue_id: other_venue_id, venue_name: "Julius'", audience_kit_event_id: nil,
                                      event_name: nil, event_start_at: nil)
      expect(client).to have_received(:catalog).with(photographer.id, audience_id: audience_id, event_id: nil, venue_id: other_venue_id)
    end

    it "needs an event or a venue" do
      expect { catalog.link!(album, audience_id: audience_id, event_id: "", venue_id: nil) }
        .to raise_error(described_class::Invalid, "Pick an event or a venue")
      expect(client).not_to have_received(:catalog)
    end

    it "refuses a venue AudienceKit doesn't list" do
      expect { catalog.link!(album, audience_id: audience_id, venue_id: SecureRandom.uuid) }
        .to raise_error(described_class::Invalid, "That venue isn't one this photographer can link to")
      expect(album.album_events).to be_empty
    end

    it "refuses an event whose venue AudienceKit doesn't list" do
      listing["audiences"].first["events"].first["venueId"] = SecureRandom.uuid

      expect { catalog.link!(album, audience_id: audience_id, event_id: event_id) }
        .to raise_error(described_class::Invalid, "That venue isn't one this photographer can link to")
    end

    it "keeps one link per audience and updates it in place" do
      first = catalog.link!(album, audience_id: audience_id, event_id: event_id)
      second = catalog.link!(album, audience_id: audience_id.upcase, venue_id: other_venue_id)

      expect(second.id).to eq first.id
      expect(album.album_events.sole).to have_attributes(audience_kit_venue_id: other_venue_id, audience_kit_event_id: nil)
    end

    it "lets AudienceKit's failure through for the caller to report" do
      allow(client).to receive(:catalog).and_raise(AudienceKit::Client::Error, "AudienceKit answered 500")

      expect { catalog.link!(album, audience_id: audience_id, event_id: event_id) }
        .to raise_error(AudienceKit::Client::Error, "AudienceKit answered 500")
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
