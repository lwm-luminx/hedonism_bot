require 'rails_helper'

RSpec.describe PhotoDescriptionJob, type: :job do
  let(:photo) { create(:photo) }

  it "works for a photo" do
    expect { described_class.perform_now photo }.not_to raise_error
  end
end
