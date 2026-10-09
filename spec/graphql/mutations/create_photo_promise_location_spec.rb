require "rails_helper"

RSpec.describe Mutations::CreatePhotoPromise, type: :graphql do
  include_context "when photo promise created"

  let(:query) do
    <<~GRAPHQL
      mutation($recordings: JSON) {
        createPhotoPromise(locationRecordings: $recordings) { promise { id } }
      }
    GRAPHQL
  end
  let(:recordings) do
    [ { "startedAt" => "2026-10-08T20:00:00Z", "stoppedAt" => "2026-10-08T20:10:00Z",
        "samples" => [ { "timestamp" => "2026-10-08T20:01:00Z", "latitude" => 39.7, "longitude" => -104.9, "accuracy" => 10 } ] } ]
  end

  it "retains validated recording history on the upload promise" do
    execute_graphql(query, variables: { recordings: recordings })
    promise = PhotoPromise.find(GlobalID.parse(Base64.decode64(data.dig("createPhotoPromise", "promise", "id"))).model_id)
    expect(promise.location_recordings).to eq(recordings)
  end

  it "rejects invalid history before creating a promise" do
    expect { execute_graphql(query, variables: { recordings: [ {} ] }) }.not_to change(PhotoPromise, :count)
  end
end
