require "rails_helper"

RSpec.describe PhotoMetadataJob do
  let(:take) { PhotoTake.create!(original_filename: "test.jpg", content_type: "image/jpeg", file_size_bytes: 100, status: "pending") }
  let(:metadata) { Struct.new(:to_hash, :date_time_original, :offset_time_original).new({}, Time.utc(2026, 10, 8, 14, 1), "-06:00") }

  before do
    take.images.attach(io: File.open(Rails.root.join("spec/fixtures/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    allow(MiniExiftool).to receive(:new).and_return(metadata)
  end

  it "uses a JPEG capture timestamp with its camera timezone offset" do
    described_class.perform_now(take)
    expect(take.reload.taken_at).to eq(Time.utc(2026, 10, 8, 20, 1))
  end

  it "passes the absolute timestamp to venue matching" do
    allow(ShootLocationHistory).to receive(:venue_at)
    described_class.perform_now(take)
    expect(ShootLocationHistory).to have_received(:venue_at).with([], Time.utc(2026, 10, 8, 20, 1))
  end

  it "skips venue inference when the camera timezone is missing" do
    allow(metadata).to receive(:offset_time_original).and_return(nil)
    allow(ShootLocationHistory).to receive(:venue_at)
    described_class.perform_now(take)
    expect(ShootLocationHistory).not_to have_received(:venue_at)
  end
end
