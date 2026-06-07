# frozen_string_literal: true

require "celery"

class UploadController < ApplicationController
  def index
  end

  def cluster
    render json: Person.cluster
  end

  def infer
    Photo.where(caption: nil).each do |p|
      Celery.enqueue "hedonism.who_dis.worker.caption_image", p.id
    end

    Photo.where(facial_metadata: nil).each do |p|
      Celery.enqueue "hedonism.who_dis.worker.extract_facial_data", p.id
    end

    head :ok
  end

  def upload
    raw_image = params[:raw_image]
    filename = ActiveStorage::Filename.new(params[:raw_image].original_filename)
    basename = File.basename(filename, ".*")
    extension = File.extname(filename).lstrip(".")

    configuration = Photo.configuration_for_extension extension

    logger.info "Performing Upload for Image #{basename} with configuration => #{configuration}"

    image_hash = Digest::SHA256.hexdigest(raw_image.read)
    photo = Photo.find_or_initialize_by(image_hash: image_hash, tenant: @tenant)
    photo.byte_size = raw_image.size
    photo.original_filename = filename
    photo.raw_image.attach(raw_image) unless photo.raw_image.attached?
    photo.image_hash = image_hash
    photo.content_type = configuration[:mime_type]

    photo.images.purge

    params[:processed_image].each do |processed_image|
      processed_configuration = Photo.configuration_for_extension File.extname(processed_image.original_filename).lstrip(".")
      photo.attach_format processed_configuration[:mime_type], processed_image, filename: processed_image.original_filename
    end

    photo.save!

    PhotoMetadataJob.perform_now photo
    if photo.has_format? "image/jpeg"
      FaceDetectionJob.perform_now photo
    else
      PhotoToJpegJob.perform_now photo
    end

    head :ok
  end
end
