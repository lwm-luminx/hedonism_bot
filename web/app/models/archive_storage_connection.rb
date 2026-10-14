class ArchiveStorageConnection < ApplicationRecord
  belongs_to :service_account
  validates :device_name, presence: true, length: { maximum: 255 }
  validate :valid_paths

  private

  def valid_paths
    return if paths.is_a?(Array) && paths.length <= 32 && paths.all? { |path| path.is_a?(String) && path.start_with?("/") && path.length <= 4096 }

    errors.add(:paths, "must contain up to 32 absolute local folder paths")
  end
end
