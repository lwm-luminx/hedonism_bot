# These request examples exercise full storage round trips and shared authentication.
# rubocop:disable RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
require 'rails_helper'
require 'uri'

# Exercises HTTP GraphQL -> signed Disk PUT -> HTTP completion, with real blobs and bytes.
RSpec.describe 'GraphQL direct uploads',  :aggregate_failures, type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:photographer) { create(:photographer, subdomain: 'upload-http') }
  let(:account) { ServiceAccount.issue!(photographer: photographer, name: "Upload tests") }
  let(:headers) { { "Authorization" => "Bearer #{account.last}" } }
  let(:other) { create(:photographer, subdomain: 'other-upload-http') }
  let(:bytes) { 'upload fixture bytes'.b }
  let(:input) do
    { originalFilename: 'test.jpg', contentType: 'image/jpeg', fileSizeBytes: bytes.bytesize,
      imageHash: Digest::SHA256.base64digest(bytes), checksum: Digest::MD5.base64digest(bytes) }
  end
  let(:register_query) do
    <<~GQL
      mutation($id: ID!, $files: [PhotoPromiseFileInput!]!) {
        attachPhotoPromiseFiles(id: $id, files: $files) {
          promise { id files { nodes { id originalFilename uploadUrl uploadHeaders status } } }
        }
      }
    GQL
  end
  let(:status_query) do
    <<~GQL
      mutation($id: ID!, $status: PhotoPromiseFileStatus!) {
        updatePhotoPromiseFileUpdate(id: $id, status: $status) { file { id status } }
      }
    GQL
  end

  let(:storage_keys) { [] }

  before do
    host! "#{photographer.subdomain}.example.com"
    ActiveStorage::Current.reset
  end

  after do
    storage_keys.each { |key| ActiveStorage::Blob.service.delete(key) }
    ActiveStorage::Current.reset
  end

  def graphql_request(query, variables = {})
    post '/graphql', params: { query: query, variables: variables }, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    JSON.parse(response.body)
  end

  def create_upload
    result = graphql_request('mutation { createPhotoPromise { promise { id } } }')
    expect(result['errors']).to be_nil
    result.dig('data', 'createPhotoPromise', 'promise', 'id')
  end

  def register(id, inputs = [ input ])
    graphql_request(register_query, { id: id, files: inputs })
  end

  def registered_file(result)
    expect(result['errors']).to be_nil
    node = result.dig('data', 'attachPhotoPromiseFiles', 'promise', 'files', 'nodes').last
    storage_keys << GlobalID::Locator.locate(node['id']).blob.key
    node
  end

  def upload_bytes(node, body = bytes)
    put URI(node['uploadUrl']).request_uri, params: body, headers: node['uploadHeaders']
  end

  it 'uploads verified bytes and persists success through GraphQL' do
    id = create_upload
    node = registered_file(register(id))
    expect(node['status']).to eq('PENDING')
    expect(node['uploadHeaders']).to include('Content-Type' => 'image/jpeg')
    upload_bytes(node)
    expect(response).to have_http_status(:no_content)
    record = GlobalID::Locator.locate(node['id'])
    expect(record.blob.download).to eq(bytes)
    result = graphql_request(status_query, { id: node['id'], status: 'SUCCESS' })
    expect(result['errors']).to be_nil
    expect(result.dig('data', 'updatePhotoPromiseFileUpdate', 'file', 'status')).to eq('SUCCESS')
    expect(record.reload.status).to eq('success')
  end

  it 'rejects completion before storage receives bytes' do
    node = registered_file(register(create_upload))
    result = graphql_request(status_query, { id: node['id'], status: 'SUCCESS' })
    expect(result['errors'].first['message']).to eq('test.jpg has not been uploaded')
    expect(GlobalID::Locator.locate(node['id']).status).to eq('pending')
  end

  it 'rejects corrupted bytes and refuses to mark the file successful' do
    node = registered_file(register(create_upload))
    corrupt = bytes.dup
    corrupt.setbyte(0, corrupt.getbyte(0) ^ 255)
    upload_bytes(node, corrupt)
    expect(response).to have_http_status(:unprocessable_content)
    result = graphql_request(status_query, { id: node['id'], status: 'SUCCESS' })
    expect(result['errors']).to be_present
  end

  it 'reuses registration after failure, refreshes the signed URL, and completes a retry' do
    id = create_upload
    node = registered_file(register(id))
    graphql_request(status_query, { id: node['id'], status: 'FAILED' })
    expect(GlobalID::Locator.locate(node['id']).status).to eq('failed')
    travel 1.minute do
      retried = registered_file(register(id))
      expect(retried['id']).to eq(node['id'])
      expect(retried['uploadUrl']).not_to eq(node['uploadUrl'])
      expect(GlobalID::Locator.locate(id).photo_promise_files.count).to eq(1)
      upload_bytes(retried)
      expect(response).to have_http_status(:no_content)
      result = graphql_request(status_query, { id: retried['id'], status: 'SUCCESS' })
      expect(result['errors']).to be_nil
    end
  end

  it 'rejects an expired signed upload URL without writing storage bytes' do
    node = registered_file(register(create_upload))
    travel (ActiveStorage.service_urls_expire_in + 1.minute) do
      upload_bytes(node)
      expect(response).to have_http_status(:not_found)
      record = GlobalID::Locator.locate(node['id'])
      expect(record.blob.service.exist?(record.blob.key)).to be(false)
      expect(record.status).to eq('pending')
    end
  end

  it 'accepts duplicate completion reports without creating another file or blob' do
    node = registered_file(register(create_upload))
    upload_bytes(node)
    expect(response).to have_http_status(:no_content)
    expect do
      2.times do
        result = graphql_request(status_query, { id: node['id'], status: 'SUCCESS' })
        expect(result['errors']).to be_nil
      end
    end.not_to change(ActiveStorage::Blob, :count)
    expect(GlobalID::Locator.locate(node['id']).status).to eq('success')
  end

  it 'keeps files with the same name but different hashes separate' do
    id = create_upload
    first = registered_file(register(id))
    second = registered_file(register(id, [ input.merge(imageHash: Digest::SHA256.base64digest('other content')) ]))
    expect(second['id']).not_to eq(first['id'])
    expect(GlobalID::Locator.locate(id).photo_promise_files.count).to eq(2)
  end

  it 'rolls back the whole batch when one file is invalid' do
    id = create_upload
    expect do
      post '/graphql', params: { query: register_query, variables: { id: id, files: [ input, input.merge(originalFilename: 'invalid.jpg', fileSizeBytes: 0) ] } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end.not_to change(ActiveStorage::Blob, :count)
    expect(GlobalID::Locator.locate(id).photo_promise_files.count).to eq(0)
  end

  it 'hides promise and file nodes and rejects writes from another photographer' do
    id = create_upload
    node = registered_file(register(id))
    other_account = ServiceAccount.issue!(photographer: other, name: "Other upload tests")
    headers["Authorization"] = "Bearer #{other_account.last}"
    host! "#{other.subdomain}.example.com"
    [ id, node['id'] ].each do |node_id|
      result = graphql_request('query($id: ID!) { node(id: $id) { id } }', { id: node_id })
      expect(result.dig('data', 'node')).to be_nil
    end
    expect(register(id)['errors'].first['message']).to eq('Photo promise not found')
    result = graphql_request(status_query, { id: node['id'], status: 'FAILED' })
    expect(result['errors'].first['message']).to eq('Upload not found')
    expect(GlobalID::Locator.locate(node['id']).status).to eq('pending')
  end

  it 'rejects a file ID where a promise ID is required and vice versa' do
    id = create_upload
    node = registered_file(register(id))
    expect(register(node['id'])['errors'].first['message']).to eq('Photo promise not found')
    result = graphql_request(status_query, { id: id, status: 'FAILED' })
    expect(result['errors'].first['message']).to eq('Upload not found')
  end

  it 'rejects an unknown status at GraphQL validation without changing the record' do
    node = registered_file(register(create_upload))
    result = graphql_request(status_query, { id: node['id'], status: 'BOGUS' })
    expect(result['errors']).to be_present
    expect(GlobalID::Locator.locate(node['id']).status).to eq('pending')
  end
end

# rubocop:enable RSpec/ExampleLength, RSpec/MultipleMemoizedHelpers
