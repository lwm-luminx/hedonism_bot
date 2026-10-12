require 'rails_helper'

describe HedonismBotSchema do
  it 'has no schema errors' do
    expect(described_class.to_definition).not_to be_empty
  end

  JSON.load_file('app/graphql/queries.json').each do |id, query|
    it "is valid against relay query #{id}" do
      expect(described_class.validate query).to be_empty
    end
  end
end

describe HedonismBotSchema, "node identity" do
  it "pins the GlobalID app so node IDs survive renaming the Ruby module" do
    expect(GlobalID.app).to eq("hedonism-bot")
  end

  it "names a take PhotoTake and identifies it by a hedonism-bot GlobalID" do
    take = PhotoTake.new(id: SecureRandom.uuid)
    expect(described_class.resolve_type(nil, take, {})).to eq(Types::PhotoTakeType)
    expect(Types::PhotoTakeType.graphql_name).to eq("PhotoTake")
    expect(Base64.urlsafe_decode64(described_class.id_from_object(take, nil, {}))).to eq("gid://hedonism-bot/PhotoTake/#{take.id}")
  end
end
