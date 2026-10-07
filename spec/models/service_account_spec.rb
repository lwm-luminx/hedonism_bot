require 'rails_helper'

RSpec.describe ServiceAccount, type: :model do
  let(:photographer) { create(:photographer) }
  let(:issued) { described_class.issue!(photographer: photographer, name: "Rick's Mac") }
  let(:account) { issued.first }
  let(:token) { issued.last }

  it "stores only a digest of the token" do
    expect(account.token_digest).not_to include(token)
  end

  it "authenticates with the token" do
    expect(described_class.authenticate(token)).to eq(account)
  end

  it "records when it was last used" do
    described_class.authenticate(token)

    expect(account.reload.last_used_at).to be_present
  end

  it "rejects a wrong token" do
    expect(described_class.authenticate("#{token}x")).to be_nil
  end

  it "rejects a revoked token" do
    account.revoke!

    expect(described_class.authenticate(token)).to be_nil
  end
end
