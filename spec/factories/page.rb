FactoryBot.define do
  factory :page do
    name { Faker::Lorem.word }
    facebook_id { Faker::Number.number(digits: 10) }
    facebook_graph do
      { description: Faker::Lorem.sentence }
    end

    cover_image { build(:image) }
  end
end
