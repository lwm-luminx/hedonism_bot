require "rails_helper"

RSpec.describe Facebook::SignedRequestVerifier do
  def sign(payload, secret: "secret")
    encoded = Base64.urlsafe_encode64(JSON.generate(payload), padding: false)
    signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", secret, encoded), padding: false)
    "#{signature}.#{encoded}"
  end

  let(:payload) { { "algorithm" => "HMAC-SHA256", "user_id" => "123", "issued_at" => 1 } }

  it "accepts a verified payload, including delayed delivery" do
    expect(described_class.call(sign(payload), secret: "secret", app_id: "app")).to eq(payload)
  end

  def invalid_requests
    [ nil, [], {}, "", "a.b.c", "!.!", sign(payload, secret: "wrong"),
              sign(payload.merge("algorithm" => "none")), sign(payload.merge("user_id" => 123)),
              sign(payload.merge("user_id" => "123x")), sign(payload.merge("app_id" => "other")),
              sign(payload.merge("issued_at" => "yesterday")), sign([]), "a" * 20_000 ]
  end

  it "rejects tampering, bad encoding, non-scalar input and invalid claims" do
    invalid_requests.each do |value|
      expect { described_class.call(value, secret: "secret", app_id: "app") }.to raise_error(described_class::InvalidRequest)
    end
  end
end
