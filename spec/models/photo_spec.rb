require "rails_helper"

RSpec.describe Photo, type: :model do
  let(:photo) { build(:photo) }

  it "prices in whole cents of a three-letter currency, free in USD by default", :aggregate_failures do
    expect(photo).to have_attributes(price_cents: 0, currency: "USD")
    expect(photo).to be_valid
  end

  it "rejects fractional or negative cents", :aggregate_failures do
    photo.price_cents = -1
    expect(photo).not_to be_valid
    photo.price_cents = 1250
    expect(photo).to be_valid
  end

  it "rejects currencies that are not a three-letter code", :aggregate_failures do
    photo.currency = "us$"
    expect(photo).not_to be_valid
    photo.currency = "EUR"
    expect(photo).to be_valid
  end
end
