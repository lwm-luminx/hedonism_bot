FactoryBot.define do
  factory :venue do
    name { "Test Venue" }
    sequence(:slug) { |n| "venue-#{n}" }
    photographer
  end
end
