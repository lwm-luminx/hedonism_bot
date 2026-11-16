# Whether the archive may read faces at all: detect them in photos, keep their embeddings and group them.
#
# A face embedding is biometric data. Illinois (BIPA), Texas and Washington (including the My Health My Data Act)
# ask for notice to, and consent from, the person in the photo before one is made, and people photographed at an
# event haven't given it. So in production this is off until FACE_PROCESSING_ENABLED is set, which should wait for
# a consent step, a published retention policy and a way to opt out. Development and test default to on.
#
# Off means: no new face detection work is queued or handed to the worker, results that arrive are dropped, and
# clustering doesn't run. Existing embeddings stay until FaceProcessing.purge! removes them.
class FaceProcessing
  def self.enabled?
    default = Rails.env.production? ? "0" : "1"
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("FACE_PROCESSING_ENABLED", default)) == true
  end

  # Deletes every stored face embedding, crop and cluster. For when face processing is off and nothing gave
  # consent for what was already made. Run with `bin/rails runner FaceProcessing.purge!`.
  def self.purge!
    PrivacyLock.biometric do
      PhotoFace.find_each(&:destroy)
      Face.find_each(&:destroy)
      PhotoTake.where.not(facial_metadata: nil).update_all(facial_metadata: nil)
    end
  end
end
