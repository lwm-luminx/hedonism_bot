require 'rails_helper'

RSpec.describe NativeLoginGrant do
  let(:photographer) { create(:photographer) }
  let(:user) { User.create!(facebook_id: "native-login-test", name: "Tester") }
  let(:verifier) { "v" * 64 }
  let!(:grant) do
    described_class.create!(code_digest: Digest::SHA256.hexdigest("one-time-code"),
                            challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false),
                            user: user, photographer: photographer, expires_at: 2.minutes.from_now)
  end

  before { PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin") }

  it "exchanges the proof for a photographer-scoped credential", :aggregate_failures do
    body = described_class.exchange(code: "one-time-code", verifier: verifier)
    expect(body[:subdomain]).to eq(photographer.subdomain)
    expect(ServiceAccount.authenticate(body[:token])).to have_attributes(user: user, photographer: photographer)
    expect(described_class.exchange(code: "one-time-code", verifier: verifier)).to be_nil
  end

  it "rejects an incorrect proof" do
    expect(described_class.exchange(code: "one-time-code", verifier: "wrong")).to be_nil
  end

  it "rejects an expired grant" do
    grant.update!(expires_at: 1.minute.ago)
    expect(described_class.exchange(code: "one-time-code", verifier: verifier)).to be_nil
  end

  it "checks authorization again at exchange" do
    user.photographer_admins.destroy_all
    expect(described_class.exchange(code: "one-time-code", verifier: verifier)).to be_nil
  end

  it "invalidates issued credentials when photographer access is removed" do
    token = described_class.exchange(code: "one-time-code", verifier: verifier)[:token]
    user.photographer_admins.destroy_all
    expect(ServiceAccount.authenticate(token)).to be_nil
  end

  context "without a photographer" do
    before { grant.update!(photographer: nil) }

    it "signs in to the person's only archive" do
      expect(described_class.exchange(code: "one-time-code", verifier: verifier)[:subdomain]).to eq(photographer.subdomain)
    end

    it "lists the archives when the person administers several", :aggregate_failures do
      other = create(:photographer)
      PhotographerAdmin.create!(user: user, photographer: other, role: "admin")
      body = described_class.exchange(code: "one-time-code", verifier: verifier)
      expect(body[:token]).to be_nil
      expect(body[:photographers].pluck(:subdomain)).to contain_exactly(photographer.subdomain, other.subdomain)
    end
  end
end
