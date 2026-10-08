class InferJob < ApplicationJob
  queue_as :default

  def perform
    PhotoTake.where(caption: nil).each do |p|
      Celery.enqueue "hedonism.who_dis.worker.caption_image", p.to_gid_param
    end

    PhotoTake.where(facial_metadata: nil, face_processing_disabled: false).each do |p|
      Celery.enqueue "hedonism.who_dis.worker.extract_facial_data", p.to_gid_param
    end
  end
end
