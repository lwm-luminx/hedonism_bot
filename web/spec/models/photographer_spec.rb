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
      expect(described_class.for_host("sam.lumiere.host")).to eq(sam)
    end

    context "with gallery domains" do
      around do |example|
        previous = Rails.configuration.x.gallery_domains
        Rails.configuration.x.gallery_domains = [ "gallery.luminx.media" ]
        example.run
      ensure
        Rails.configuration.x.gallery_domains = previous
      end

      it "treats a gallery domain's subdomains like the service domain's" do
        expect(described_class.for_host("Sam.Gallery.Luminx.Media")).to eq(sam)
      end

      it "finds nobody for unknown, nested or unconfigured gallery hosts" do
        hosts = %w[nobody.gallery.luminx.media a.sam.gallery.luminx.media sam.gallery.lovewins.media]
        expect(hosts.map { |host| described_class.for_host(host) }).to all(be_nil)
      end

      it "still prefers a registered domain" do
        create(:photographer_domain, photographer: luminx, hostname: "sam.gallery.luminx.media")
        expect(described_class.for_host("sam.gallery.luminx.media")).to eq(luminx)
      end
    end

    it "finds nobody for an unknown host" do
      expect(described_class.for_host("hedonism-bot-f74c04df64ff.herokuapp.com")).to be_nil
    end
  end

  describe "#host" do
    it "is the subdomain under the service domain" do
      expect(described_class.new(subdomain: "sam").host).to eq "sam.#{Rails.configuration.x.service_domain}"
    end
  end
end
