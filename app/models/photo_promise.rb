class PhotoPromise < ApplicationRecord
  belongs_to :photographer
  belongs_to :album, optional: true
  has_many :photo_promise_files

  # The photographer (tenant) this record belongs to; GraphQL only resolves IDs owned by the request's.
  def owner_photographer_id
    photographer_id
  end

  # The album uploads land in when the uploader didn't name one.
  def album_for_uploads
    album || photographer.albums.find_or_create_by!(name: "Uploads #{created_at.to_date.iso8601}")
  end

  # Turns an uploaded file into (part of) a photo take: files sharing a basename (DSC00001.ARW and
  # DSC00001.HIF) become one take, with the RAW as raw_image and the rest as images.
  def ingest(file)
    with_lock do
      file.reload
      next file.photo_take if file.photo_take

      take = photo_promise_files.where.not(photo_take_id: nil).find { |f| f.basename == file.basename }&.photo_take
      take ||= PhotoTake.create!(photo: Photo.create!(album: album_for_uploads), **file.take_attributes)

      if file.raw?
        take.update!(file.take_attributes)
        take.raw_image.attach(file.blob)
      else
        take.images.attach(file.blob)
      end
      file.update!(photo_take: take)
      take
    end.tap { |take| enqueue_processing(take, file) }
  end

  private

  def enqueue_processing(take, file)
    if file.raw?
      PhotoMetadataJob.perform_later(take)
    else
      PhotoToJpegJob.perform_later(take)
    end
  end
end
