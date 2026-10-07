require 'rails_helper'

RSpec.describe Photographer, type: :model do
  it "has a valid factory" do
    expect(build(:photographer)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:photographer, name: nil)).not_to be_valid
  end

  it "is invalid without a subdomain" do
    expect(build(:photographer, subdomain: nil)).not_to be_valid
  end

  it "is invalid with a duplicate subdomain" do
    create(:photographer, subdomain: "test")
    expect(build(:photographer, subdomain: "test")).not_to be_valid
  end

  describe ".for_host" do
    let!(:luminx) { create(:photographer, subdomain: "luminx") }
    let!(:sam) { create(:photographer, subdomain: "sam") }

    before { create(:photographer_domain, photographer: luminx, hostname: "gallery.lovewins.media") }

    it "finds the photographer by a registered domain" do
      expect(described_class.for_host("gallery.lovewins.media")).to eq(luminx)
    end

    it "matches domains case-insensitively" do
      expect(described_class.for_host("Gallery.LoveWins.Media")).to eq(luminx)
    end

    it "falls back to the host's first label as a subdomain" do
      expect(described_class.for_host("sam.hedonism.bot")).to eq(sam)
    end

    it "finds nobody for an unknown host" do
      expect(described_class.for_host("hedonism-bot-f74c04df64ff.herokuapp.com")).to be_nil
    end
  end
end
