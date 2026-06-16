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
