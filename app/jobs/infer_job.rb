class InferJob < ApplicationJob
  queue_as :default

  def perform
    PhotoTake.where(caption: nil).each do |p|
      PhotoInferenceWork.enqueue! p, "hedonism.who_dis.worker.caption_image"
    end

    PhotoTake.where(facial_metadata: nil, face_processing_disabled: false).each do |p|
      PhotoInferenceWork.enqueue! p, "hedonism.who_dis.worker.extract_facial_data"
    end
  end
end
