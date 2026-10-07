require 'rails_helper'

RSpec.describe Mutations::UpdatePhotoPromiseFileUpdate, type: :graphql do
  include ActiveJob::TestHelper

  let(:photographer) { create(:photographer) }
  let(:promise) { PhotoPromise.create!(photographer: photographer, album: Album.create!(photographer: photographer, name: "SD 2026-10-07")) }
  let(:raw) { add_file("DSC00001.ARW", "image/x-sony-arw", "raw bytes") }
  let(:heif) { add_file("DSC00001.HIF", "image/heif", "heif bytes") }

  def query
    <<~GQL
      mutation($id: ID!, $status: PhotoPromiseFileStatus!) {
        updatePhotoPromiseFileUpdate(id: $id, status: $status) { file { status photo { id } } }
      }
    GQL
  end

  def add_file(name, content_type, body)
    file = promise.photo_promise_files.create!(
      original_filename: name, content_type: content_type, file_size_bytes: body.bytesize,
      image_hash: Digest::SHA256.digest(body), checksum: Digest::MD5.base64digest(body)
    )
    file.blob.upload(StringIO.new(body))
    file
  end

  def complete(file, as: photographer)
    execute_graphql(query, variables: { id: file.to_gid_param, status: "SUCCESS" }, context: { photographer: as })
  end

  context "when both files of a shot are uploaded" do
    before do
      complete(heif)
      complete(raw)
    end

    def take = raw.reload.photo_take

    it "makes one photo take in the promise's album" do
      expect(take.photo.album.name).to eq("SD 2026-10-07")
    end

    it "pairs the files on the same take" do
      expect(heif.reload.photo_take).to eq(take)
    end

    it "attaches the RAW as the raw image" do
      expect(take.raw_image.download).to eq("raw bytes")
    end

    it "attaches the HEIF as an image" do
      expect(take.images.map(&:download)).to eq([ "heif bytes" ])
    end

    it "describes the take with the RAW" do
      expect(take).to have_attributes(original_filename: "DSC00001.ARW", content_type: "image/x-sony-arw")
    end
  end

  it "enqueues metadata extraction for a RAW" do
    expect { complete(raw) }.to have_enqueued_job(PhotoMetadataJob)
  end

  it "refuses a file that was never uploaded" do
    file = promise.photo_promise_files.create!(original_filename: "DSC2.ARW", content_type: "image/x-sony-arw", file_size_bytes: 3, image_hash: "x", checksum: Digest::MD5.base64digest("abc"))
    complete(file)

    expect(response_errors.first["message"]).to include("has not been uploaded")
  end

  it "refuses another photographer's upload" do
    complete(raw, as: Photographer.create!(name: "Other", subdomain: "other"))

    expect(raw.reload.photo_take).to be_nil
  end
end
