class FacebookDataDeletionJob < ApplicationJob
  queue_as :default

  def perform(receipt_id)
    receipt = DataDeletionRequest.find_by(id: receipt_id)
    return unless receipt
    # Keep a row lock for the complete operation. A crash rolls back state; blob deletes are repeatable.
    receipt.with_lock do
      return if receipt.status.in?(%w[completed needs_attention])
      receipt.update!(status: "processing", attempts: receipt.attempts + 1)
      UserDataDeletionService.new(receipt).call
      receipt.update!(status: receipt.review_reasons.empty? ? "completed" : "needs_attention",
                      completed_at: receipt.review_reasons.empty? ? Time.current : nil,
                      error_category: nil, next_attempt_at: nil)
    end
  rescue StandardError
    if receipt
      receipt.with_lock do
        unless receipt.status.in?(%w[completed needs_attention])
          attempts = receipt.attempts + 1
          receipt.update!(attempts: attempts, status: attempts >= 10 ? "needs_attention" : "retrying",
                          error_category: "cleanup_failed", next_attempt_at: [ 2**attempts, 3600 ].min.seconds.from_now)
        end
      end
      Rails.logger.error("Facebook deletion failed receipt=#{receipt.id}")
    end
  end
end
