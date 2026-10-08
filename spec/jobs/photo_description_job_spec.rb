require 'rails_helper'

RSpec.describe PhotoDescriptionJob, type: :job do
  let(:photo) { create(:photo) }
  let(:take) do
    PhotoTake.create!(photo: photo, original_filename: "test.jpg", file_size_bytes: 1,
                      content_type: "image/jpeg", status: "pending")
  end

  it "accepts a photo without any takes" do
    expect { described_class.perform_now photo }.not_to change(PhotoInferenceWork, :count)
  end

  it "queues a photo's individual takes" do
    take
    described_class.perform_now photo
    expect(PhotoInferenceWork.where(photo_take: take).pluck(:task)).to eq([ "hedonism.who_dis.worker.caption_image" ])
  end

  it "queues a take directly without duplicating outstanding work" do
    2.times { described_class.perform_now take }
    expect(PhotoInferenceWork.where(photo_take: take).count).to eq(1)
  end
end
