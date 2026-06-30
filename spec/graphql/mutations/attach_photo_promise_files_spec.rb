require 'rails_helper'

RSpec.shared_context 'when promise has files' do
  include_context 'when photo promise created'

  let(:photo_promise) {
    execute_graphql(create_promise_query)['data']['createPhotoPromise']['promise']
  }

  let(:inputs) do
    [
      build(:photo_promise_raw_input),
      build(:photo_promise_processed_input)
    ].map do |i|
      {
        originalFilename: i.original_filename,
        contentType: i.content_type,
        fileSizeBytes: i.file_size_bytes,
        imageHash: Base64.strict_encode64(i.image_hash)
      }
    end
  end
end

RSpec.describe Mutations::AttachPhotoPromiseFiles, type: :graphql do
  include_context 'when promise has files'

  let(:create_promise_files) do
    <<~GQL
      mutation($id: ID!, $files: [PhotoPromiseFileInput!]!) {
        attachPhotoPromiseFiles(id: $id, files: $files) {
          promise {
            id
            files {
              nodes {
                id
                uploadUrl
              }
            }
          }
        }
      }
    GQL
  end

  describe "with valid inputs" do
    it "uploads with a set of file inputs" do
      execute_graphql(create_promise_files, variables: { id: photo_promise['id'], files: inputs })


      aggregate_failures do
        expect(data.dig("attachPhotoPromiseFiles", "promise", "files", "nodes")).to be_present
        expect(data.dig("attachPhotoPromiseFiles", "promise", "files", "nodes").size).to eq(inputs.size)
      end
    end
  end
end
