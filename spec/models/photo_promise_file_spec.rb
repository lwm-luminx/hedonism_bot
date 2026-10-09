# Blob reservation checks metadata and storage together.
# rubocop:disable RSpec/ExampleLength
require 'rails_helper'

RSpec.describe PhotoPromiseFile,  :aggregate_failures, type: :model do
  let(:photographer) { create(:photographer, subdomain: 'upload-model') }
  let(:promise) { PhotoPromise.create!(photographer: photographer) }
  let(:bytes) { 'upload fixture bytes'.b }
  let(:attributes) do
    { photo_promise: promise, original_filename: 'test.jpg', content_type: 'image/jpeg',
      file_size_bytes: bytes.bytesize, image_hash: Digest::SHA256.digest(bytes),
      checksum: Digest::MD5.base64digest(bytes) }
  end

  before { ActiveStorage::Current.url_options = { host: 'test.host', protocol: 'http' } }
  after { ActiveStorage::Current.reset }

  it 'reserves and retains a blob with the storage checksum, without uploading bytes' do
    record = described_class.create!(attributes)
    blob = record.reload.blob
    expect(blob.filename.to_s).to eq('test.jpg')
    expect(blob.byte_size).to eq(bytes.bytesize)
    expect(blob.content_type).to eq('image/jpeg')
    expect(blob.checksum).to eq(Digest::MD5.base64digest(bytes))
    expect(record.image_hash).to eq(Digest::SHA256.digest(bytes))
    expect(record.status).to eq('pending')
    expect(record.upload_url).to be_present
    expect(blob.service.exist?(blob.key)).to be(false)
  end

  %i[original_filename content_type image_hash photo_promise].each do |attribute|
    it "requires #{attribute}" do
      record = described_class.new(attributes.merge(attribute => nil))
      expect(record).not_to be_valid
      expect(record.errors[attribute]).to be_present
    end
  end

  [ nil, 0, -1 ].each do |size|
    it "rejects a file size of #{size.inspect} before reserving a blob" do
      record = described_class.new(attributes.merge(file_size_bytes: size))
      expect { record.save }.not_to change(ActiveStorage::Blob, :count)
      expect(record.errors[:file_size_bytes]).to be_present
    end
  end

  [ '', 'not-base64', Digest::SHA256.base64digest('bytes') ].each do |checksum|
    it "rejects malformed or non-MD5 checksums (#{checksum.inspect})" do
      record = described_class.new(attributes.merge(checksum: checksum))
      expect { record.save }.not_to change(ActiveStorage::Blob, :count)
      expect(record.errors[:checksum]).to be_present
    end
  end

  it 'rejects unknown states' do
    record = described_class.new(attributes.merge(status: 'invented'))
    expect(record).not_to be_valid
    expect(record.errors[:status]).to be_present
  end

  it 'allows a persisted file to change state without resupplying the transient checksum' do
    record = described_class.create!(attributes)
    persisted = described_class.find(record.id)
    expect(persisted.checksum).to be_nil
    expect { persisted.update!(status: 'failed') }.not_to change(ActiveStorage::Blob, :count)
    expect(persisted.reload.status).to eq('failed')
  end
end

# rubocop:enable RSpec/ExampleLength
