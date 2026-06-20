FactoryBot.define do
  factory :audience do
    name { Faker::Name.name }
    subdomain { Faker::Internet.domain_name }
  end

  factory :default_audience, parent: :audience do
    name { 'Default Audience' }
    subdomain { 'default' }

    to_create do |instance|
      Audience.first_or_create(name: instance.name, subdomain: instance.subdomain)
    end
  end
end
