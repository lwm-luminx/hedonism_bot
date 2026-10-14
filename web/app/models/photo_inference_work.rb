class PhotoInferenceWork < ApplicationRecord
  TASKS = %w[hedonism.who_dis.worker.caption_image hedonism.who_dis.worker.extract_facial_data].freeze
  belongs_to :photographer
  belongs_to :photo_take
  belongs_to :service_account, optional: true
  validates :task, inclusion: { in: TASKS }

  def self.enqueue!(photo, task)
    return unless photo.owner_photographer_id

    work = find_or_create_by!(photo_take: photo, task: task) { |row| row.photographer_id = photo.owner_photographer_id }
    work.with_lock { work.update!(state: "pending", attempts: 0) if work.state == "completed" }
    work
  end

  def self.claim(account)
    scope = where(photographer: account.photographer)
    scope.where(state: "running").where("lease_expires_at <= ?", Time.current).where("attempts >= 3").update_all(state: "failed")
    transaction do
      work = scope.where("state = 'pending' OR (state IN ('running', 'retry') AND lease_expires_at <= ? AND attempts < 3)", Time.current)
                  .order(:created_at).lock("FOR UPDATE SKIP LOCKED").first
      return unless work
      return work.update!(state: "failed") && nil if work.photo_take.owner_photographer_id != account.photographer_id
      return work.update!(state: "completed") && nil if work.face_task? && work.photo_take.face_processing_disabled?

      work.update!(state: "running", service_account: account, lease_token: SecureRandom.hex(24),
                   lease_expires_at: 2.minutes.from_now, deadline_at: 1.hour.from_now, attempts: work.attempts + 1)
      work
    end
  end

  def face_task?
    task == "hedonism.who_dis.worker.extract_facial_data"
  end

  def leased_to?(account, token)
    service_account_id == account.id && lease_token == token && state == "running" &&
      lease_expires_at.future? && deadline_at.future? && photo_take.owner_photographer_id == account.photographer_id
  end
end
