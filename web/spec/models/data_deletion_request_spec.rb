require "rails_helper"

RSpec.describe DataDeletionRequest do
  self.use_transactional_tests = false

  let(:facebook_id) { "#{Time.now.to_i}#{SecureRandom.random_number(1_000_000)}" }
  let(:user) { User.create!(facebook_id: facebook_id) }
  let(:ids) { concurrent_receipt_ids }

  before do
    user
    ids
  end

  after do
    described_class.where(subject_digest: described_class.subject_digest(facebook_id)).delete_all
    user.delete
  end

  def concurrent_receipt_ids
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do
          ready << true
          start.pop
          described_class.accept!({ "user_id" => facebook_id }, "delivery-#{facebook_id}").id
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.map(&:value)
  ensure
    threads&.each(&:join)
  end

  it "returns the same receipt to concurrent duplicate deliveries" do
    expect(ids.uniq.size).to eq(1)
  end

  it "persists only one receipt for concurrent duplicate deliveries" do
    expect(described_class.where(id: ids).count).to eq(1)
  end

  it "blocks login after concurrent acceptance" do
    expect(user.reload.deletion_pending_at).to be_present
  end
end
