FactoryBot.define do
  factory :user do
    facebook_id { Faker::Number.number(digits: 10) }
    name { Faker::Name.name }
    email_address { Faker::Internet.email }
  end
end
