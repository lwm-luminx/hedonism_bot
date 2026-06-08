require 'rails_helper'

RSpec.describe Photo, type: :model do
  it "has a valid factory" do
    expect(build(:photo)).to be_valid
  end

  it "is invalid with invalid status" do
    expect(build(:photo, status: "invalid")).not_to be_valid
  end
end
