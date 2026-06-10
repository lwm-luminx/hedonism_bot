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
end
