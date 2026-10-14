FactoryBot.define do
  factory :face do
    photographer { create(:default_photographer) }
  end
end
