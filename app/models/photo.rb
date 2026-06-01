class Photo < ApplicationRecord
  STATUSES = %w[pending processing processed failed].freeze

  belongs_to :tenant
  belongs_to :venue, optional: true

  has_many :photo_people, dependent: :destroy
  has_many :people, through: :photo_people
  has_many :versions, class_name: "PhotoVersion", dependent: :destroy

  has_one_attached :image

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
end
