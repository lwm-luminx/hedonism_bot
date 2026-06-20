FactoryBot.define do
  sequence(:promise_image_file) { |n| "DSC0000#{(n % 6) + 1}" }

  factory :photo_promise_file do
    transient do
      promise_image_file { "#{generate(:promise_image_file)}.hif" }
    end

    content_type { "image/heif" }

    original_filename { promise_image_file }

    photo_promise

    image_hash { Faker::Crypto.sha256 }

    file_size_bytes { Faker::Number.number(digits: 5) }
  end
end
