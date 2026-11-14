require "rails_helper"

RSpec.describe FaceProcessing do
  around do |example|
    before = ENV["FACE_PROCESSING_ENABLED"]
    example.run
    ENV["FACE_PROCESSING_ENABLED"] = before
  end

  it "is on in test unless switched off, and off in production unless switched on" do
    ENV.delete("FACE_PROCESSING_ENABLED")
    expect(described_class).to be_enabled

    allow(Rails.env).to receive(:production?).and_return(true)
    expect(described_class).not_to be_enabled
    ENV["FACE_PROCESSING_ENABLED"] = "1"
    expect(described_class).to be_enabled
  end

  it "keeps clustering from making faces while off" do
    create_list :photo_face, 12
    ENV["FACE_PROCESSING_ENABLED"] = "0"

    expect { ClusterFacesJob.perform_now }.not_to change(Face, :count)
  end

  it "purges stored embeddings and clusters" do
    create_list :photo_face, 2

    described_class.purge!

    expect(PhotoFace.count).to eq 0
    expect(Face.count).to eq 0
  end
end
