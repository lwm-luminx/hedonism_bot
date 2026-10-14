FactoryBot.define do
  factory :photo do
    album { create(:default_album) }
  end
end
