require "rails_helper"

RSpec.describe "App Review device code", type: :request do
  let!(:review) { create(:photographer, subdomain: "review") }
  let(:code) { "ABCD-1234-EF56-7890-ABCD" }

  def exchange(given)
    post "/auth/device/exchange", params: { code: given }, as: :json
  end

  before { host! "api.lumiere.host" }

  around do |example|
    with_review_code(code) { example.run }
  end

  def with_review_code(value)
    previous = ENV.fetch("REVIEW_DEVICE_CODE", nil)
    ENV["REVIEW_DEVICE_CODE"] = value
    yield
  ensure
    ENV["REVIEW_DEVICE_CODE"] = previous
  end

  it "signs in to the review photographer every time it is used", :aggregate_failures do
    2.times do
      exchange(code.downcase)
      expect(ServiceAccount.authenticate(response.parsed_body["token"]).photographer).to eq(review)
    end
  end

  it "rejects other codes" do
    exchange("ABCD-1234-EF56-7890-ABCE")
    expect(response).to have_http_status(:unauthorized)
  end

  it "is off when no review code is configured" do
    with_review_code(nil) { exchange(code) }
    expect(response).to have_http_status(:unauthorized)
  end

  it "does nothing until the review photographer exists" do
    review.update!(subdomain: "renamed")
    exchange(code)
    expect(response).to have_http_status(:unauthorized)
  end
end
