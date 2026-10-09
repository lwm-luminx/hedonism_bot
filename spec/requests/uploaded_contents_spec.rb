require 'rails_helper'

RSpec.describe "Uploaded content preflight", type: :request do
  let(:photographer) { create(:photographer, subdomain: "hash-check") }
  let(:account) { ServiceAccount.issue!(photographer: photographer, name: "Cogsworth") }
  let(:digest) { Digest::SHA256.digest("hello") }
  let(:hash_string) { Base64.strict_encode64(digest) }
  let(:headers) { { "Authorization" => "Bearer #{account.last}" } }

  before { host! "api.lumiere.host" }

  def uploaded_file(owner = photographer)
    promise = create(:photo_promise, photographer: owner)
    take = PhotoTake.create!(original_filename: "test.arw", content_type: "image/x-sony-arw", file_size_bytes: 5)
    file = create(:photo_promise_file, photo_promise: promise, photo_take: take, status: "success",
                  image_hash: digest, checksum: Base64.strict_encode64(Digest::MD5.digest("hello")), file_size_bytes: 5)
    file.blob.service.upload(file.blob.key, StringIO.new("hello"), checksum: file.blob.checksum)
    file
  end

  def check_hashes(hashes = [ hash_string ])
    post "/auth/uploaded_contents", params: { hashes: hashes }, headers: headers, as: :json
  end

  it "requires bearer authentication" do
    post "/auth/uploaded_contents", params: { hashes: [ hash_string ] }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "recognizes completed content with stored bytes" do
    uploaded_file
    check_hashes
    expect(response.parsed_body["hashes"]).to eq([ hash_string ])
  end

  it "does not reveal another photographer's contents" do
    uploaded_file(create(:photographer, subdomain: "other-hash-check"))
    check_hashes
    expect(response.parsed_body["hashes"]).to eq([])
  end

  it "does not skip a failed upload" do
    uploaded_file.update!(status: "failed")
    check_hashes
    expect(response.parsed_body["hashes"]).to eq([])
  end

  it "does not skip contents whose bytes are missing" do
    file = uploaded_file
    file.blob.service.delete(file.blob.key)
    check_hashes
    expect(response.parsed_body["hashes"]).to eq([])
  end

  it "rejects malformed hashes" do
    check_hashes([ "bad" ])
    expect(response).to have_http_status(:bad_request)
  end
end
