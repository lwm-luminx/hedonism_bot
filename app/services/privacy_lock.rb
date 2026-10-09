# Transaction-scoped PostgreSQL locks coordinate deletion with login and biometric writers.
class PrivacyLock
  def self.with(key)
    ApplicationRecord.transaction do
      lock_id = Digest::SHA256.digest(key).unpack1("q>")
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
      yield
    end
  end

  def self.biometric(&block)
    with("privacy:biometric-writes", &block)
  end
end
