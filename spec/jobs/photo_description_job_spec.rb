require 'rails_helper'

RSpec.describe PhotoDescriptionJob, type: :job do
  let(:photo) { create(:photo) }

  let(:take) do
    PhotoTake.create!(photo: photo, original_filename: "caption.jpg", file_size_bytes: 1,
                      content_type: "image/jpeg", status: "pending")
  end

  it "queues the photo's takes for captioning", :aggregate_failures do
    take
    expect { described_class.perform_now photo }.to change(PhotoInferenceWork, :count).by(1)
    expect(PhotoInferenceWork.last.photo_take).to eq(take)
  end

  it "accepts a take directly" do
    expect { described_class.perform_now take }.to change(PhotoInferenceWork, :count).by(1)
  end

  it "works for a photo" do
    expect { described_class.perform_now photo }.not_to raise_error
  end
end
