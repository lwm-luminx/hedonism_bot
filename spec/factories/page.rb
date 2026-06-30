FactoryBot.define do
  factory :page do
    name { Faker::Lorem.word }
    facebook_id { Faker::Number.number(digits: 10) }
    facebook_graph do
      { description: Faker::Lorem.sentence }
    end

    image { create(:image) }
    cover_image { create(:image) }
  end
end
