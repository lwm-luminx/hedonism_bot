require 'rails_helper'

RSpec.describe InferJob, type: :job do
  it "executes with a photo" do
    expect { described_class.perform_now }.not_to raise_error
  end
end
