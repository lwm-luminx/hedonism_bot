FactoryBot.define do
  sequence(:image_file) { |n| "DSC0000#{(n % 6) + 1}" }

  factory :photo_take do
    transient do
      file { generate(:image_file) }
    end

    photo

    image_hash {
      filename = Rails.root.join("spec/fixtures/#{file}.arw")
      filename.open do |f|
        Digest::SHA256.file(f).digest
      end
    }

    file_size_bytes {
      File.stat(Rails.root.join("spec/fixtures/#{file}.arw")).size
    }

    original_filename { "#{file}.arw" }

    status { "pending" }
    taken_at { Date.yesterday }
    content_type { "image/x-sony-arw" }

    after(:create) do |photo, context|
      raw_photo = Rails.root.join("spec/fixtures/#{context.file}.arw")
      processed_photo = Rails.root.join("spec/fixtures/#{context.file}.hif")
      photo.raw_image.attach(io: File.open(raw_photo), filename: "#{context.file}.arw", content_type: 'image/x-sony-arw')
      photo.images.attach(io: File.open(processed_photo), filename: "#{context.file}.hif", content_type: 'image/heif')
      PhotoToJpegJob.perform_now photo
    end
  end
end
