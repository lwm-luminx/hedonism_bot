require "rails_helper"

# An album's AudienceKit link carries into the photography contract, so changing it has to reach the next pull.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
RSpec.describe AlbumEvent, type: :model do
  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "album-event-sam", active: true) }
  let(:album) { Album.create!(photographer: photographer, name: "Drag Bingo") }
  let(:audience_id) { SecureRandom.uuid }
  let(:grant) { PhotographyGrant.issue!(photographer: photographer, audience_id: audience_id).first }

  def processed_photo(in_album = album)
    Photo.create!(album: in_album).tap do |photo|
      PhotoTake.create!(photo: photo, status: "processed", original_filename: "a.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    end
  end

  def link!(**attributes)
    album.album_events.create!(audience_id: audience_id, audience_kit_venue_id: SecureRandom.uuid, **attributes)
  end

  def age(*publications)
    PhotographyPublication.where(id: publications.map(&:id)).update_all(updated_at: 1.day.ago) # rubocop:disable Rails/SkipsModelValidations
  end

  it "needs AudienceKit UUIDs for the audience and the venue" do
    expect(album.album_events.build(audience_id: "hot-mess", audience_kit_venue_id: SecureRandom.uuid)).not_to be_valid
    expect(album.album_events.build(audience_id: audience_id, audience_kit_venue_id: nil)).not_to be_valid
    expect(album.album_events.build(audience_id: audience_id, audience_kit_venue_id: SecureRandom.uuid)).to be_valid
  end

  it "allows one link per audience for an album, but one per album in an audience" do
    link!
    expect(album.album_events.build(audience_id: audience_id, audience_kit_venue_id: SecureRandom.uuid)).not_to be_valid

    other_album = Album.create!(photographer: photographer, name: "Brunch")
    expect(other_album.album_events.build(audience_id: audience_id, audience_kit_venue_id: SecureRandom.uuid)).to be_valid
  end

  it "finds the link for a grant's audience, ignoring case and other audiences" do
    album.album_events.create!(audience_id: SecureRandom.uuid, audience_kit_venue_id: SecureRandom.uuid)
    link = link!
    grant.audience_id = audience_id.upcase

    expect(described_class.for_grant(album.reload, grant)).to eq link
    expect(described_class.for_grant(nil, grant)).to be_nil
    expect(described_class.for_grant(Album.create!(photographer: photographer, name: "Unlinked"), grant)).to be_nil
  end

  it "marks the album's live publications to its audience changed when linked, relinked or unlinked" do
    photo = processed_photo
    publication = grant.publish!(photo)
    age(publication)

    link = link!
    expect(publication.reload.updated_at).to be > 1.minute.ago

    age(publication)
    link.update!(audience_kit_event_id: SecureRandom.uuid)
    expect(publication.reload.updated_at).to be > 1.minute.ago

    age(publication)
    link.destroy!
    expect(publication.reload.updated_at).to be > 1.minute.ago
  end

  it "leaves other audiences, other albums and tombstones alone" do
    other_grant = PhotographyGrant.issue!(photographer: photographer, audience_id: SecureRandom.uuid).first
    photo = processed_photo
    elsewhere = grant.publish!(processed_photo(Album.create!(photographer: photographer, name: "Brunch")))
    other_audience = other_grant.publish!(photo)
    removed = grant.publish!(processed_photo).tap(&:remove!)
    age(elsewhere, other_audience, removed)

    link!

    [ elsewhere, other_audience, removed ].each { |publication| expect(publication.reload.updated_at).to be < 1.hour.ago }
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
