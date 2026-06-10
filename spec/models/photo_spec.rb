require 'rails_helper'

RSpec.describe Photo, type: :model do
  describe "validation errors" do
    it "is invalid with invalid status" do
      expect(build(:photo, status: "invalid")).to be_invalid
    end

    it "is invalid without filename" do
      expect(build(:photo, original_filename: nil)).to be_invalid
    end

    it "is invalid with without a Photographer" do
      expect(build(:photo, photographer_id: nil)).to be_invalid
    end

    it "is invalid without a mime_type" do
      expect(build(:photo, content_type: nil)).to be_invalid
    end

    it "is invalid without a filesize" do
      expect(build(:photo, file_size_bytes: nil)).to be_invalid
    end
  end

  describe "valid image" do
    let_it_be(:model) { create(:photo) }

    before do
      ActiveStorage::Current.url_options = {
        protocol: 'http',
        host: 'localhost',
        port: 5000
      }
    end

    it "has a valid factory" do
      expect(model).to be_valid
    end

    it "has a raw image" do
      expect(model.raw_image).to be_present
    end

    it "has a non-raw image" do
      expect(model.images).not_to be_empty
    end

    it "has a composite image" do
      expect(model.composite_image).to be_present
    end

    it "has a preview url" do
      expect(model.preview_url).to be_present
    end
  end
end
