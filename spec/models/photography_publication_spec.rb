require "rails_helper"

# rubocop:disable RSpec/ExampleLength

RSpec.describe PhotographyPublication, type: :model do
  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "sam-pub", active: true) }
  let(:grant) { PhotographyGrant.issue!(photographer: photographer, audience_id: SecureRandom.uuid).first }
  let(:photo) { Photo.create!(album: Album.create!(photographer: photographer, name: "Shared")) }

  it "remembers the photo's id as photo_key and when it was published", :aggregate_failures do
    publication = grant.publish!(photo)
    expect(publication).to have_attributes(photo_key: photo.id, removed?: false)
    expect(publication.published_at).to be_within(2.seconds).of(Time.current)
  end

  it "keeps a tombstone when the photo is deleted" do
    publication = grant.publish!(photo)
    photo.destroy!
    expect(publication.reload).to have_attributes(photo_id: nil, photo_key: photo.id, removed?: true)
  end

  it "keeps a tombstone when the photo is unpublished, and revives it on republish with a new published_at", :aggregate_failures do
    publication = grant.publish!(photo)
    first_published_at = publication.published_at
    grant.unpublish!(photo)
    expect(publication.reload).to be_removed
    travel 1.minute
    expect(grant.publish!(photo)).to eq publication
    expect(publication.reload).to have_attributes(removed?: false, photo: photo)
    expect(publication.published_at).to be > first_published_at
  end

  it "tells whether a photo is currently served by its previews", :aggregate_failures do
    expect(photo.published?).to be false
    grant.publish!(photo)
    expect(photo.published?).to be true
    grant.update!(expires_at: 1.minute.ago)
    expect(photo.published?).to be false
  end
end
# rubocop:enable RSpec/ExampleLength
