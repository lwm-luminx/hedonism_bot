class Photo < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :caption_search, against: [ :caption ], using: { tsearch: { prefix: true } }

  STATUSES = %w[pending processing processed failed hidden].freeze

  APPLE_FORMATS = %w[image/heic image/heif]
  COMPOSITE_PREFERENCE_LIST = %w[image/heif image/heic image/jpeg image/png]

  RAW_FORMATS = {
    arw: { mime_type: "image/x-sony-arw" }
  }

  PROCESSED_FORMATS = {
    hif: { mime_type: "image/heif", variant: :heif },
    jpg: { mime_type: "image/jpeg", variant: :jpeg },
    jpeg: { mime_type: "image/jpeg", variant: :jpeg },
    png: { mime_type: "image/png", variant: :png }
  }

  CONFIGURATIONS = {
    arw: { mime_type: "image/x-sony-arw", variant: :raw, raw: true },
    hif: { mime_type: "image/heif", variant: :heif },
    jpg: { mime_type: "image/jpeg", variant: :jpeg },
    jpeg: { mime_type: "image/jpeg", variant: :jpeg },
    png: { mime_type: "image/png", variant: :png }
  }

  belongs_to :tenant
  belongs_to :venue, optional: true

  has_many :photo_people, dependent: :destroy
  has_many :people, through: :photo_people

  has_one_attached :raw_image
  has_many_attached :images

  validates :status, inclusion: { in: STATUSES }
  validates_uniqueness_of :image_hash

  scope :for_date, ->(date) { where(folder_date: date) }
  scope :processed, -> { where(status: "processed") }

  # Group photos by the date they were taken (folder_date), newest day first.
  # Returns an ordered hash of { Date => [Photo, ...] }.
  def self.grouped_by_folder_date
    order(folder_date: :desc, created_at: :desc)
      .group_by { |p| p.folder_date || p.created_at.to_date }
  end

  def mark_processing!
    update!(status: "processing")
  end

  def mark_processed!(faces_detected:, face_data: {}, folder_date: nil, taken_at: nil)
    update!(
      status: "processed",
      faces_detected: faces_detected,
      face_data: face_data,
      folder_date: folder_date || self.folder_date || (taken_at || created_at).to_date,
      taken_at: taken_at || self.taken_at
    )
  end

  def mark_failed!(error)
    update!(status: "failed", processing_error: error.to_s.first(500))
  end


  def self.configuration_for_extension(extension)
    CONFIGURATIONS[extension.downcase.to_sym].reverse_merge raw: false
  end

  def metadata_image
    images.filter { |i| i.blob.content_type == self.content_type }.first
  end

  def composite_image
    images.first { |i| COMPOSITE_PREFERENCE_LIST.include? i.blob.content_type }
  end

  def preview_url
    images.select { |i| i.blob.content_type == "image/jpeg" }.first&.url
  end

  def has_format?(mime_type)
    images.any? { |image| image.blob.content_type == mime_type }
  end

  def attach_format(mime_type, processed_file, filename:)
    if has_format?(mime_type)
      if APPLE_FORMATS.include?(mime_type)
        mime_formats = APPLE_FORMATS
      else
        mime_formats = [ mime_type ]
      end
      others = images.filter { |image| mime_formats.include? image.blob.content_type  }
      others.each { |image| image.purge_later }
    end

    images.attach(
      io: processed_file,
      filename: filename,
      content_type: mime_type,
      identify: APPLE_FORMATS.include?(mime_type)
    )
  end

  def update_faces(faces)
    self.photo_people.clear
    faces.each do |face|
      person_photo = photo_people.create(
        arc_face_embedding: face.embedding,
        confidence: face.face_confidence,
        bounding_box: face.facial_area
      )
      person = Person.nearest_neighbors(:arc_face_embedding, face.embedding, distance: "cosine", threshold: 0.1).first


      FacePreviewExtractJob.perform_now person_photo
    end
    save!
  end
end
