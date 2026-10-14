require 'rails_helper'

RSpec.describe PhotographerDomain, type: :model do
  it "normalizes the hostname" do
    expect(build(:photographer_domain, hostname: " Gallery.Luminx.Media. ").hostname).to eq("gallery.luminx.media")
  end

  it "rejects something that isn't a hostname" do
    expect(build(:photographer_domain, hostname: "not a host")).not_to be_valid
  end

  it "allows a hostname only once" do
    create(:photographer_domain, hostname: "gallery.luminx.media")
    expect(build(:photographer_domain, hostname: "gallery.luminx.media")).not_to be_valid
  end
end
