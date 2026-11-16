require "rails_helper"

RSpec.describe FaceProcessing do
  around do |example|
    before = ENV["FACE_PROCESSING_ENABLED"]
    example.run
    ENV["FACE_PROCESSING_ENABLED"] = before
  end

  describe ".enabled?" do
    before { ENV.delete("FACE_PROCESSING_ENABLED") }

    it "is on in test unless switched off" do
      expect(described_class).to be_enabled
    end

    it "is off in production unless switched on" do
      allow(Rails.env).to receive(:production?).and_return(true)
      expect(described_class).not_to be_enabled
    end

    it "is on in production once switched on" do
      allow(Rails.env).to receive(:production?).and_return(true)
      ENV["FACE_PROCESSING_ENABLED"] = "1"
      expect(described_class).to be_enabled
    end
  end

  it "keeps clustering from making faces while off" do
    create_list :photo_face, 12
    ENV["FACE_PROCESSING_ENABLED"] = "0"

    expect { ClusterFacesJob.perform_now }.not_to change(Face, :count)
  end

  describe ".purge!" do
    before do
      create_list :photo_face, 2
      described_class.purge!
    end

    it "removes stored embeddings" do
      expect(PhotoFace.count).to eq 0
    end

    it "removes clusters" do
      expect(Face.count).to eq 0
    end
  end
end
