FactoryBot.define do
  factory :album do
    name { Faker::Lorem.word }
    photographer { create(:default_photographer) }

    factory :default_album do
      name { "Default Album" }

      initialize_with { Album.find_or_create_by(attributes) }
    end
  end
end
