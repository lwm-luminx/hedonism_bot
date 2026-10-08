require "rails_helper"

RSpec.describe "Client errors", :aggregate_failures, type: :request do
  let(:warnings) { [] }

  before do
    mock_photographer
    allow(Rails.logger).to receive(:warn) { |line| warnings << line }
  end

  def report(body)
    post "/client_errors", params: body, headers: { "Host" => "test.hedonism.local", "CONTENT_TYPE" => "text/plain" }
  end

  def logged_reports
    warnings.grep(/\A\[client_error\] /).map { |line| JSON.parse(line.delete_prefix("[client_error] ")) }
  end

  it "logs a beacon report with the photographer" do
    report({ kind: "boundary", message: "TypeError: boom", url: "https://test.hedonism.local/" }.to_json)

    expect(response).to have_http_status(:no_content)
    expect(logged_reports.sole).to include("kind" => "boundary", "message" => "TypeError: boom",
                                           "photographer" => Photographer.default_photographer.subdomain)
  end

  it "truncates long fields and drops unknown ones" do
    report({ message: "x" * 5_000, password: "hunter2" }.to_json)

    expect(logged_reports.sole["message"].length).to eq 1_000
    expect(logged_reports.sole).not_to have_key("password")
  end

  it "ignores bodies that are not a JSON object" do
    report("not json")
    report("[1, 2]")

    expect(response).to have_http_status(:no_content)
    expect(logged_reports).to be_empty
  end

  it "stops logging an IP after the rate limit" do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

    (ClientErrorsController::RATE_LIMIT + 5).times { report({ message: "again" }.to_json) }

    expect(logged_reports.size).to eq ClientErrorsController::RATE_LIMIT
  end
end
