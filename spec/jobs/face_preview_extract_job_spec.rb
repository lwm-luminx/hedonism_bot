require 'rails_helper'

RSpec.describe FacePreviewExtractJob, type: :job do
  let(:photo) { create(:photo_face) }

  it "operates on a created photo" do
    expect { described_class.perform_now photo }.not_to raise_error
  end
end
