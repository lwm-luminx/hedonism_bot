class FaceDetectionJob < ApplicationJob
  def perform(photo)
    Celery.enqueue "hedonism.who_dis.worker.extract_facial_data", photo.id
    Celery.enqueue "hedonism.who_dis.worker.caption_image", photo.id
  end
end
