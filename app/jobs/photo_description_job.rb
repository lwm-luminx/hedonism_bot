class PhotoDescriptionJob < ApplicationJob
  queue_as :default

  def perform(photo)
    PhotoInferenceWork.enqueue! photo, "hedonism.who_dis.worker.caption_image"
  end
end
