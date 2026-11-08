require "rails_helper"

# The credential AudienceKit pulls photos with: one photographer, one audience, until it expires or is revoked.
# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe PhotographyGrant, type: :model do
  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "grant-sam", active: true) }
  let(:audience_id) { SecureRandom.uuid }
  let(:issued) { described_class.issue!(photographer: photographer, audience_id: audience_id) }
  let(:grant) { issued.first }
  let(:token) { issued.last }

  def processed_photo(owner = photographer)
    Photo.create!(album: Album.create!(photographer: owner, name: "Shared")).tap do |photo|
      PhotoTake.create!(photo: photo, status: "processed", original_filename: "a.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    end
  end

  it "issues a prefixed token and keeps only its digest" do
    expect(token).to start_with "hbpg_"
    expect(grant.token_digest).to eq Digest::SHA256.hexdigest(token)
    expect(grant.attributes.values).not_to include token
  end

  it "needs an AudienceKit audience UUID" do
    expect { described_class.issue!(photographer: photographer, audience_id: "hot-mess") }
      .to raise_error(ActiveRecord::RecordInvalid, /Audience is invalid/)
  end

  it "authenticates its own token only while it and its photographer are live" do
    expect(described_class.authenticate(token)).to eq grant
    expect(described_class.authenticate(token.delete_prefix("hbpg_"))).to be_nil
    expect(described_class.authenticate("hbpg_#{SecureRandom.base58(40)}")).to be_nil
    expect(described_class.authenticate(nil)).to be_nil
    expect(described_class.authenticate([ token ])).to be_nil

    photographer.update!(active: false)
    expect(described_class.authenticate(token)).to be_nil
    photographer.update!(active: true)

    grant.update!(expires_at: 1.second.ago)
    expect(described_class.authenticate(token)).to be_nil
    expect(grant).not_to be_active

    grant.update!(expires_at: 1.day.from_now)
    expect(described_class.authenticate(token)).to eq grant
    expect(grant).to be_active

    grant.update!(revoked_at: Time.current)
    expect(described_class.authenticate(token)).to be_nil
    expect(grant).not_to be_active
  end

  it "compares audience ids case-insensitively and only with strings" do
    expect(grant.for_audience?(audience_id.upcase)).to be true
    expect(grant.for_audience?(SecureRandom.uuid)).to be false
    expect(grant.for_audience?(nil)).to be false
  end

  it "publishes a photo once, and revives its tombstone on republish" do
    photo = processed_photo
    first = grant.publish!(photo)
    expect(grant.publish!(photo)).to eq first
    expect(grant.shows?(photo)).to be true

    grant.unpublish!(photo)
    expect(grant.shows?(photo)).to be false
    expect(first.reload).to be_removed

    expect(grant.publish!(photo)).to eq first
    expect(first.reload).not_to be_removed
    expect(grant.photography_publications.count).to eq 1
  end

  it "doesn't show a photo once it belongs to someone else" do
    photo = processed_photo
    grant.publish!(photo)
    other = Photographer.create!(name: "Other", subdomain: "grant-other", active: true)
    photo.update!(album: Album.create!(photographer: other, name: "Theirs"))

    expect(grant.shows?(photo)).to be false
    expect(grant.publications.map(&:photo)).to eq []
  end

  it "lists only showable photos without updated_since, and every change with it" do
    shown = processed_photo
    pending = Photo.create!(album: Album.create!(photographer: photographer, name: "Pending"))
    PhotoTake.create!(photo: pending, status: "pending", original_filename: "b.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    removed = processed_photo
    [ shown, pending, removed ].each { |photo| grant.publish!(photo) }
    grant.unpublish!(removed)

    expect(grant.publications.map(&:photo)).to eq [ shown ]
    expect(grant.publications(updated_since: 1.minute.ago).map(&:photo_key)).to contain_exactly(shown.id, pending.id, removed.id)
    expect(grant.publications(updated_since: 1.minute.from_now)).to be_empty
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
