require 'rails_helper'

RSpec.describe ArchiveAlbumJob, type: :job do
  let(:album) { Album.create!(photographer: create(:photographer), name: "Pride 2026", storage_transition: "archiving") }
  let!(:take) { create_take_with_files(album, raw: "raw bytes") }

  def service_names
    take.reload
    { raw: take.raw_image.blob.service_name }.merge(take.images.to_h { |i| [ i.content_type, i.blob.service_name ] })
  end

  context "when archiving" do
    before { described_class.perform_now(album, "archive") }

    it "moves originals to the archive service and keeps the preview hot" do
      expect(service_names).to eq(raw: "test_archive", "image/heif" => "test_archive", "image/jpeg" => "test")
    end

    it "keeps the original readable" do
      expect(take.reload.raw_image.download).to eq("raw bytes")
    end

    it "deletes the hot copy" do
      expect(ActiveStorage::Blob.services.fetch(:test).exist?(take.raw_image.key)).to be(false)
    end

    it "clears the album's transition" do
      expect(album.reload.storage_transition).to be_nil
    end

    it "is safe to run again" do
      described_class.perform_now(album, "archive")

      expect(take.reload.raw_image.download).to eq("raw bytes")
    end
  end

  context "when restoring" do
    before do
      described_class.perform_now(album, "archive")
      described_class.perform_now(album, "restore")
    end

    it "moves everything back to the hot service" do
      expect(service_names.values.uniq).to eq([ "test" ])
    end

    it "keeps the original readable" do
      expect(take.reload.raw_image.download).to eq("raw bytes")
    end
  end
end
