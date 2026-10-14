require 'rails_helper'

RSpec.describe WorkerChannel, type: :channel do
  # Protocol examples exercise complete claim/update sequences.
  # rubocop:disable RSpec/ExampleLength
  let(:photographer) { create(:photographer) }
  let(:account) { ServiceAccount.issue!(photographer: photographer, name: "Cogsworth").first }
  let(:album) { create(:album, photographer: photographer) }
  let(:photo) do
    PhotoTake.create!(photo: create(:photo, album: album), original_filename: "test.jpg",
                      file_size_bytes: 1, content_type: "image/jpeg", status: "pending")
  end
  let(:task) { "hedonism.who_dis.worker.caption_image" }

  before do
    stub_connection(service_account: account)
    connection.define_singleton_method(:authorized?) { true }
    subscribe(protocol: 1)
  end

  it "claims only the authenticated photographer's work", :aggregate_failures do
    work = PhotoInferenceWork.enqueue!(photo, task)
    other = ServiceAccount.issue!(photographer: create(:photographer, subdomain: "other"), name: "Other").first
    expect(PhotoInferenceWork.claim(other)).to be_nil
    perform :claim
    expect(transmissions.last[:id]).to eq(work.id)
  end

  it "deduplicates retransmitted claims" do
    PhotoInferenceWork.enqueue!(photo, task)
    2.times { perform :claim }
    expect(transmissions.map { |message| message[:lease_token] }.uniq.size).to eq(1)
  end

  it "rejects a stale result without modifying the photo" do
    work = PhotoInferenceWork.enqueue!(photo, task)
    perform :claim
    lease = transmissions.last[:lease_token]
    work.update!(lease_expires_at: 1.minute.ago)
    perform :complete, id: work.id, lease_token: lease, result: { caption: "Stale", description: "Stale" }
    expect(photo.reload.caption).to be_nil
  end

  it "commits results and permits completion replay", :aggregate_failures do
    work = PhotoInferenceWork.enqueue!(photo, task)
    perform :claim
    lease = transmissions.last[:lease_token]
    2.times { perform :complete, id: work.id, lease_token: lease, result: { caption: "New", description: "Description" } }
    expect(photo.reload.caption).to eq("New")
    expect(work.reload.state).to eq("completed")
  end

  it "does not renew an expired lease" do
    work = PhotoInferenceWork.enqueue!(photo, task)
    perform :claim
    lease = transmissions.last[:lease_token]
    work.update!(lease_expires_at: 1.minute.ago)
    perform :heartbeat, id: work.id, lease_token: lease
    expect(transmissions.last[:type]).to eq("lease_rejected")
  end

  it "does not dispatch when access has been revoked" do
    PhotoInferenceWork.enqueue!(photo, task)
    allow(connection).to receive(:authorized?).and_return(false)
    connection.define_singleton_method(:close) { |**_options| }
    perform :claim
    expect(transmissions).to be_empty
  end
  # rubocop:enable RSpec/ExampleLength
end
