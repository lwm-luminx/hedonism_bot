require 'rails_helper'

RSpec.describe "Upload", type: :request do
  before do
    mock_tenant
  end

  describe "POST /upload" do
    it "fails if raw_image is missing" do
      # Expecting 500 because it tries to access .read on nil
      expect { post "/upload" }.to raise_error(NoMethodError)
    end
  end
end
