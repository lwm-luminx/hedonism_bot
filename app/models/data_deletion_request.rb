class DataDeletionRequest < ApplicationRecord
  STATES = %w[pending processing retrying needs_attention completed].freeze
  validates :status, inclusion: { in: STATES }
  scope :unfinished, -> { where.not(status: "completed") }
  scope :due, -> { where(status: %w[pending retrying]).where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current) }

  def self.subject_digest(facebook_id)
    key = Rails.application.key_generator.generate_key("facebook-data-deletion-subject-v1", 32)
    OpenSSL::HMAC.hexdigest("SHA256", key, "#{FACEBOOK_APP_ID}:#{facebook_id}")
  end

  def self.with_subject(facebook_id, &block)
    PrivacyLock.with("facebook-deletion:#{subject_digest(facebook_id)}", &block)
  end

  def self.accept!(payload, signed_request)
    with_subject(payload.fetch("user_id")) do
      digest = subject_digest(payload.fetch("user_id"))
      payload_digest = Digest::SHA256.hexdigest(signed_request)
      existing = where(app_id: FACEBOOK_APP_ID.to_s, subject_digest: digest)
                 .where("payload_digest = :digest OR :digest = ANY(replay_digests)", digest: payload_digest).first
      next existing if existing
      existing = unfinished.find_by(app_id: FACEBOOK_APP_ID.to_s, subject_digest: digest)
      if existing
        existing.with_lock { existing.update!(replay_digests: existing.replay_digests | [ payload_digest ]) }
        next existing
      end

      user = User.lock.find_by(facebook_id: payload.fetch("user_id"))
      user&.update!(deletion_pending_at: Time.current, facebook_token: nil, facebook_scopes: nil)
      create!(app_id: FACEBOOK_APP_ID.to_s, subject_digest: digest, payload_digest: payload_digest,
              confirmation_code: SecureRandom.hex(16), user_id: user&.id,
              review_context: user ? { facebook_id: user.facebook_id, user_id: user.id,
                                     name: user.name, first_name: user.first_name, last_name: user.last_name,
                                     email_address: user.email_address, image_id: user.image_id,
                                     page_ids: UserPage.where(user_id: user.id).pluck(:page_id) } : nil,
              review_reasons: user ? [ "legacy_external_copies_and_provenance" ] : [])
    end
  end

  def self.pending_for?(facebook_id)
    unfinished.exists?(app_id: FACEBOOK_APP_ID.to_s, subject_digest: subject_digest(facebook_id))
  end

  # Short-lived, encrypted lookup material for processor cleanup and the restore journal.
  # Never include this in status responses, logs, or job arguments.
  def review_context=(value)
    self.encrypted_review_context = value && self.class.context_encryptor.encrypt_and_sign(value, purpose: "deletion-review")
  end

  def review_context
    return unless encrypted_review_context
    self.class.context_encryptor.decrypt_and_verify(encrypted_review_context, purpose: "deletion-review")
  end

  def self.context_encryptor
    key = Rails.application.key_generator.generate_key("facebook-data-deletion-review-v1", 32)
    ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: JSON)
  end

  def public_status
    case status
    when "completed" then "completed"
    when "needs_attention", "retrying" then "delayed"
    else "processing"
    end
  end

  # Operator attests external copies/provenance/backup handling after local and blob cleanup.
  def confirm_review!
    with_lock do
      raise "Local cleanup is incomplete" unless local_deleted_at && cleanup_manifest.empty?
      update!(reviewed_at: Time.current, review_reasons: [], status: "completed",
              completed_at: Time.current, user_id: nil, encrypted_review_context: nil, error_category: nil)
    end
  end
end
