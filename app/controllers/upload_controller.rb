# frozen_string_literal: true

require "celery"

class UploadController < ApplicationController
  def cluster
    Celery.enqueue "hedonism.who_dis.worker.cluster_faces", nil do |r|
      r.each do |cluster, person_photo_id|
        next if person_photo_id.nil?
        p = PhotoPerson.find(person_photo_id)
        p.cluster_number = cluster
        p.save
      end

      Person.delete_all
      PhotoPerson.all.group_by(&:cluster_number).each do |cluster, person_photos|
        person = Person.create(tenant: @tenant)

        person_photos.each do |p|
          p.person = person
          p.save
        end
      end
    end

    head :ok
  end

  def index
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
    photo.raw_image.attach(raw_image)
    photo.image_hash = image_hash
    photo.content_type = configuration[:mime_type]

    photo.images.purge

    params[:processed_image].each do |processed_image|
      processed_configuration = Photo.configuration_for_extension File.extname(processed_image.original_filename).lstrip(".")
      photo.attach_format processed_configuration[:mime_type], processed_image, filename: processed_image.original_filename
    end

    photo.save!

    PhotoMetadataJob.perform_later photo.id
    unless photo.has_format? "image/jpeg"
      PhotoToJpegJob.perform_later photo.id
    end

    if photo.has_format? "image/jpeg"
      FaceDetectionJob.perform_later photo
    end

    head :ok
  end
end
