require 'rails_helper'

RSpec.describe PhotoTake, type: :model do
  describe "multiple (5) photo takes for one photographer" do
    let_it_be(:photographer) { create(:default_photographer) }
    let_it_be(:photo_takes) { create_list(:photo_take, 5) }

    it "has 5 photo takes" do
      expect(photo_takes.count).to eq(5)
    end

    it "gets 5 photo takes with a query" do
      expect(described_class.with_photographer(photographer).count).to eq(5)
    end
  end

  describe "validation errors" do
    it "is invalid with invalid status" do
      expect(build(:photo_take, status: "invalid")).to be_invalid
    end

    it "is invalid without filename" do
      expect(build(:photo_take, original_filename: nil)).to be_invalid
    end


    it "is invalid without a mime_type" do
      expect(build(:photo_take, content_type: nil)).to be_invalid
    end

    it "is invalid without a filesize" do
      expect(build(:photo_take, file_size_bytes: nil)).to be_invalid
    end
  end

  describe "valid image" do
    let_it_be(:model) { create(:photo_take) }

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
