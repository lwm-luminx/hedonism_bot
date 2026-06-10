# frozen_string_literal: true

require "celery"

class UploadController < ApplicationController
  def upload
    raw_image = params[:raw_image]
    filename = ActiveStorage::Filename.new(params[:raw_image].original_filename)
    basename = File.basename(filename, ".*")
    extension = File.extname(filename).lstrip(".")

    configuration = Photo.configuration_for_extension extension

    logger.info "Performing Upload for Image #{basename} with configuration => #{configuration}"

    image_hash = Digest::SHA256.hexdigest(raw_image.read)
    photo = Photo.find_or_initialize_by(image_hash: image_hash, photographer: photographer)
    photo.file_size_bytes = raw_image.size
    photo.original_filename = filename.to_s
    photo.raw_image.attach(raw_image) unless photo.raw_image.attached?
    photo.image_hash = image_hash
    photo.content_type = configuration[:mime_type]

    photo.images.purge

    params[:processed_image].each do |processed_image|
      processed_configuration = Photo.configuration_for_extension(File.extname(processed_image.original_filename).lstrip("."))
      mime = processed_configuration[:mime_type]
      photo.attach_format mime, processed_image, filename: processed_image.original_filename
    end

    photo.save!

    PhotoMetadataJob.perform_later photo
    if photo.has_format? "image/jpeg"
      FaceDetectionJob.perform_later photo
    else
      PhotoToJpegJob.perform_later photo
    end

    head :ok
  end
end
