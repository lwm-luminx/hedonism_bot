require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:pair) { ServiceAccount.issue!(photographer: create(:photographer), name: "Cogsworth") }

  it "authenticates a bearer credential" do
    connect "/cable", headers: { "Authorization" => "Bearer #{pair.last}" }
    expect(connection.service_account).to eq(pair.first)
  end

  it "rejects a missing credential" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects a revoked credential" do
    pair.first.revoke!
    expect { connect "/cable", headers: { "Authorization" => "Bearer #{pair.last}" } }.to have_rejected_connection
  end
end
