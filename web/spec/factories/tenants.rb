FactoryBot.define do
  factory :photographer do
    name { "Test Photographer" }

    subdomain { "test-photographer" }

    active { true }

    factory :default_photographer do
      initialize_with { Photographer.first_or_create }
    end
  end
end
