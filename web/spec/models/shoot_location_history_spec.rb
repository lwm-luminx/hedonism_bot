require "rails_helper"

RSpec.describe ShootLocationHistory do
  let(:sample) { { "timestamp" => "2026-10-08T20:01:00Z", "latitude" => 39.7, "longitude" => -104.9, "accuracy" => 10 } }
  let(:recordings) { [ { "startedAt" => "2026-10-08T20:00:00Z", "stoppedAt" => "2026-10-08T20:10:00Z", "samples" => [ sample ] } ] }

  it "validates coordinates and recording boundaries" do
    expect(described_class.valid?(recordings)).to be true
  end

  it "rejects invalid coordinates" do
    sample["latitude"] = 100
    expect(described_class.valid?(recordings)).to be false
  end

  it "matches an absolute capture time with a timezone offset" do
    expect(described_class.sample_at(recordings, Time.iso8601("2026-10-08T14:01:30-06:00"))).to eq(sample)
  end

  it "does not match outside a session or across a reception gap" do
    expect(described_class.sample_at(recordings, Time.iso8601("2026-10-08T19:59:59Z"))).to be_nil
  end

  it "does not match across a reception gap" do
    expect(described_class.sample_at(recordings, Time.iso8601("2026-10-08T20:09:00Z"))).to be_nil
  end

  it "rejects malformed samples" do
    sample.delete("timestamp")
    expect(described_class.valid?(recordings)).to be false
  end
end
