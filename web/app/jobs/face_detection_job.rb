class FaceDetectionJob < ApplicationJob
  def perform(photo)
    return unless FaceProcessing.enabled?
    return if photo.reload.face_processing_disabled?

    PhotoInferenceWork.enqueue! photo, "hedonism.who_dis.worker.extract_facial_data"
  end
end
