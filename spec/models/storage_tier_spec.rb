require 'rails_helper'

RSpec.describe StorageTier, type: :model do
  describe ".move_all" do
    let(:album) { Album.create!(photographer: create(:photographer), name: "Pride 2026") }

    before do
      create_take_with_files(album)
      ArchiveAlbumJob.perform_now(album, "archive")
    end

    it "returns how many blobs it moved" do
      archived_count = ActiveStorage::Blob.where(service_name: "test_archive").count
      expect(described_class.move_all(from: "test_archive")).to eq(archived_count).and be_positive
    end

    it "leaves every blob on the hot service" do
      described_class.move_all(from: "test_archive")
      expect(ActiveStorage::Blob.distinct.pluck(:service_name)).to eq([ "test" ])
    end

    it "keeps the moved files readable" do
      described_class.move_all(from: "test_archive")
      expect(ActiveStorage::Blob.all).to all(satisfy { |blob| blob.download.present? })
    end

    it "refuses to move the hot service onto itself" do
      expect { described_class.move_all(from: "test") }.to raise_error(ArgumentError)
    end

    it "refuses an unknown service" do
      expect { described_class.move_all(from: "nope") }.to raise_error(KeyError)
    end
  end
end
