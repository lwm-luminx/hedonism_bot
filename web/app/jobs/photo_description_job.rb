class PhotoDescriptionJob < ApplicationJob
  queue_as :default

  def perform(photo)
    takes = photo.is_a?(Photo) ? photo.photo_takes : [ photo ]
    takes.each { |take| PhotoInferenceWork.enqueue! take, "hedonism.who_dis.worker.caption_image" }
  end
end
