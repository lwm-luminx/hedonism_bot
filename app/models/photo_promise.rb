class PhotoPromise < ApplicationRecord
  belongs_to :photographer
  has_many :photo_promise_files
end
