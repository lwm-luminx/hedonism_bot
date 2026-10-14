require 'rails_helper'

RSpec.describe StorageUsage, type: :model do
  subject(:usage) { described_class.new(photographer) }

  let(:photographer) { create(:photographer) }
  let(:album) { Album.create!(photographer: photographer, name: "Pride 2026") }
  let(:other_album) { Album.create!(photographer: photographer, name: "Afterparty") }

  def pride = usage.albums.find { |a| a.name == "Pride 2026" }

  before do
    create_take_with_files(album)
    create_take_with_files(album)
    create_take_with_files(other_album, raw: "r" * 1000)
  end

  it "totals bytes per album, originals separately from previews" do
    expect(pride).to have_attributes(photo_count: 2, bytes: 1100, original_bytes: 1000, archived_bytes: 0)
  end

  it "totals bytes across albums" do
    expect(usage.total_bytes).to eq(1100 + 1250)
  end

  context "when an album is archived" do
    before { ArchiveAlbumJob.perform_now(album, "archive") }

    it "counts its originals as archived" do
      expect(pride.archived_bytes).to eq(1000)
    end

    it "splits the total into hot and archived bytes" do
      expect(usage).to have_attributes(archived_bytes: 1000, hot_bytes: 1350)
    end
  end

  it "ignores other photographers' albums" do
    other = Photographer.create!(name: "Other", subdomain: "other")
    create_take_with_files(Album.create!(photographer: other, name: "Theirs"))

    expect(usage.albums.map(&:name)).to eq([ "Afterparty", "Pride 2026" ])
  end
end
