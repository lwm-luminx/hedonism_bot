require 'rails_helper'

RSpec.describe PhotoMetadataJob, type: :job do
  let(:photographer) { Photographer.default_photographer }

  let(:photo) { create(:photo, photographer: photographer) }

  it "gets metadata on a created photo" do
    expect(described_class.perform_now(photo)).to be_truthy
  end
end
