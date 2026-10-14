require 'rails_helper'

RSpec.describe Face, type: :model do
  it "has a valid factory" do
    expect(build(:face)).to be_valid
  end
end
