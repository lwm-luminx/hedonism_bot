require 'rails_helper'

RSpec.describe Venue, type: :model do
  it "has a valid factory" do
    expect(build(:venue)).to be_valid
  end

  it "is invalid without a name" do
    expect(build(:venue, name: nil)).not_to be_valid
  end
end
