class FaceDetectionJob < ApplicationJob
  def perform(photo)
    return if photo.reload.face_processing_disabled?

    Celery.enqueue "hedonism.who_dis.worker.extract_facial_data", photo.to_gid_param
  end
end
