class DispatchDataDeletionsJob < ApplicationJob
  def perform
    DataDeletionRequest.due.find_each { |receipt| FacebookDataDeletionJob.perform_later(receipt.id) }
    DataDeletionRequest.unfinished.where("created_at < ?", 24.hours.ago).find_each do |receipt|
      Rails.logger.error("Facebook deletion overdue receipt=#{receipt.id}")
    end
  end
end
