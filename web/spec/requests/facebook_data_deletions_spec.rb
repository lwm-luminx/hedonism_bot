require "rails_helper"

RSpec.describe "Facebook data deletion", type: :request do
  before do
    stub_const("FACEBOOK_APP_SECRET", "test-secret")
    stub_const("FACEBOOK_APP_ID", "app-123")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("DATA_DELETION_PUBLIC_ORIGIN", "").and_return("https://privacy.example.com")
    allow(FacebookDataDeletionJob).to receive(:perform_later)
    host! "no-gallery.example.com"
  end

  def signed_request(id = "123", issued_at: 1)
    encoded = Base64.urlsafe_encode64(JSON.generate(algorithm: "HMAC-SHA256", user_id: id, issued_at: issued_at), padding: false)
    signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("SHA256", FACEBOOK_APP_SECRET, encoded), padding: false)
    "#{signature}.#{encoded}"
  end

  def callback(value = signed_request)
    post "/callbacks/facebook/data-deletion", params: { signed_request: value }
  end

  context "with CSRF protection enabled and no tenant" do
    let!(:user) { User.create!(facebook_id: "123", name: "Private Name", facebook_token: "secret") }

    around do |example|
      previous = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end

    before { callback }

    it "accepts a signed callback without a CSRF token" do
      expect(response).to have_http_status(:ok)
    end

    it "returns the required response fields" do
      expect(response.parsed_body.keys.sort).to eq(%w[confirmation_code url])
    end

    it "generates an alphanumeric confirmation code" do
      expect(response.parsed_body["confirmation_code"]).to match(/\A[0-9a-f]{32}\z/)
    end

    it "uses the trusted status origin" do
      expect(response.parsed_body["url"]).to start_with("https://privacy.example.com/privacy/deletion/")
    end

    it "marks the account for deletion" do
      expect(user.reload.deletion_pending_at).to be_present
    end

    it "clears the Facebook token" do
      expect(user.reload.facebook_token).to be_nil
    end

    it "blocks login" do
      expect { User.from_facebook_graph({ "id" => "123" }) }.to raise_error(User::DeletionPending)
    end

    context "when viewing the returned status URL" do
      before { get URI(response.parsed_body["url"]).path }

      it "serves a public page" do
        expect(response).to have_http_status(:ok)
      end

      it "reports progress" do
        expect(response.body).to include("being processed")
      end

      it "does not disclose the subject's name" do
        expect(response.body).not_to include("Private Name")
      end

      it "prevents caching" do
        expect(response.headers["Cache-Control"]).to eq("no-store")
      end

      it "credits Love Wins Media" do
        expect(response.body).to include("A Love Wins Media product")
      end
    end
  end

  context "when enqueue fails" do
    before do
      allow(FacebookDataDeletionJob).to receive(:perform_later).and_raise(StandardError)
      callback
    end

    it "deduplicates repeated callbacks" do
      expect { callback }.not_to change(DataDeletionRequest, :count)
    end

    it "returns the same receipt on retry" do
      body = response.parsed_body
      callback
      expect(response.parsed_body).to eq(body)
    end

    it "persists work for later dispatch" do
      expect(DataDeletionRequest.last.status).to eq("pending")
    end
  end

  it "rejects invalid signatures without writes" do
    expect { callback("bad.signature") }.not_to change(DataDeletionRequest, :count)
  end

  it "returns bad request for an invalid signature" do
    callback("bad.signature")
    expect(response).to have_http_status(:bad_request)
  end

  it "rejects oversized bodies before parameter parsing" do
    post "/callbacks/facebook/data-deletion", params: "signed_request=#{'a' * 40_000}",
         headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
    expect(response).to have_http_status(:content_too_large)
  end

  it "redacts status capabilities from Rails request paths" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/privacy/deletion/#{'a' * 32}"))
    expect(request.filtered_path).to eq("/privacy/deletion/[FILTERED]")
  end

  context "without a configured origin" do
    before { allow(ENV).to receive(:fetch).with("DATA_DELETION_PUBLIC_ORIGIN", "").and_return("") }

    it "does not accept work" do
      expect { callback }.not_to change(DataDeletionRequest, :count)
    end

    it "reports that the service is unavailable" do
      callback
      expect(response).to have_http_status(:service_unavailable)
    end
  end

  context "with an unknown subject" do
    before do
      callback
      receipt = DataDeletionRequest.last
      FacebookDataDeletionJob.perform_now(receipt.id)
      get "/privacy/deletion/#{receipt.confirmation_code}.json"
    end

    it "completes the request" do
      expect(response.parsed_body["status"]).to eq("completed")
    end

    it "does not expose account existence" do
      expect(response.parsed_body.keys).not_to include("user_found", "user_id")
    end
  end

  it "returns not found for an unknown confirmation code" do
    get "/privacy/deletion/#{'0' * 32}"
    expect(response).to have_http_status(:not_found)
  end
end
