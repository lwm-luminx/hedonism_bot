require 'rails_helper'

RSpec.describe ClusterFacesJob, type: :job do
  before do
    create_list :photo_face, 5
  end

  it "works with valid data" do
    expect { described_class.perform_now }.not_to raise_error
  end
end
