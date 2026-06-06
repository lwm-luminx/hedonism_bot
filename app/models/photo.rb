class Photo < ApplicationRecord
  STATUSES = %w[pending processing processed failed hidden].freeze

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
    images.select { |i| i.blob.content_type == self.content_type }.first
  end

  def composite_image
    images.select { |i| i.blob.content_type == "image/heif" }.first
  end
end
