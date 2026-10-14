FactoryBot.define do
  factory :photographer_domain do
    photographer
    sequence(:hostname) { |n| "gallery#{n}.example.com" }
  end
end
