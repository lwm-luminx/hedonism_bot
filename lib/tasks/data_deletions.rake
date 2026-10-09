namespace :data_deletions do
  desc "List delayed deletion receipts (no user identifiers)"
  task pending: :environment do
    DataDeletionRequest.unfinished.find_each do |receipt|
      puts "#{receipt.id} #{receipt.status} #{receipt.created_at.iso8601} #{receipt.review_reasons.join(',')}"
    end
  end

  desc "Confirm external/provenance/backup review: RECEIPT_ID=uuid CONFIRM_REVIEW=complete"
  task confirm_review: :environment do
    abort "Set CONFIRM_REVIEW=complete after completing the operator checklist" unless ENV["CONFIRM_REVIEW"] == "complete"
    receipt = DataDeletionRequest.find(ENV.fetch("RECEIPT_ID"))
    receipt.confirm_review!
    puts "Completed receipt #{receipt.id}"
  end

  desc "Retry failed cleanup: RECEIPT_ID=uuid"
  task retry: :environment do
    receipt = DataDeletionRequest.find(ENV.fetch("RECEIPT_ID"))
    receipt.with_lock do
      abort "Already complete" if receipt.status == "completed"
      receipt.update!(status: "pending", next_attempt_at: nil, error_category: nil, attempts: 0)
    end
    FacebookDataDeletionJob.perform_later(receipt.id)
  end
end
