FactoryBot.define do
  sequence(:promise_image_file) { |n| "DSC0000#{(n % 6) + 1}" }
  sequence(:photo_promise_raw_input_file) { |n| "DSC0000#{(n % 6) + 1}" }
  sequence(:photo_promise_processed_input_file) { |n| "DSC0000#{(n % 6) + 1}" }
  factory :photo_promise_file do
    transient do
      promise_image_file { "#{generate(:promise_image_file)}.hif" }
    end

    content_type { "image/heif" }

    original_filename { promise_image_file }

    photo_promise

    image_hash { Faker::Crypto.sha256 }

    file_size_bytes { Faker::Number.number(digits: 5) }

    factory :photo_promise_raw_input do
      transient do
        file_name { "#{generate(:photo_promise_raw_input_file)}.arw" }
      end

      original_filename { file_name }
      content_type { "image/x-sony-arw" }
      image_hash { fixture_hash file_name }
      file_size_bytes { fixture_size file_name }
    end

    factory :photo_promise_processed_input do
      transient do
        file_name { "#{generate(:photo_promise_processed_input_file)}.hif" }
      end

      original_filename { file_name }
      content_type { "image/heif" }
      image_hash { fixture_hash file_name }
      file_size_bytes { fixture_size file_name }
    end
  end
end
