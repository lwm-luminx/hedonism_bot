FactoryBot.define do
  factory :photo_person do
    photo { create(:photo) }
    confidence { 0.95 }
    arc_face_embedding { (1..512).map { rand(-1.0..1.0) } }
    bounding_box { { "x": 0, "y": 0, "w": 10, "h": 10 } }

    after(:create) do |photo_person|
      test_image = Rails.root.join('spec/fixtures/test.jpg')
      photo_person.photo.images.attach(io: File.open(test_image), filename: 'face_test.jpg', content_type: 'image/jpeg')
      photo_person.face_image.attach(io: File.open(test_image), filename: 'face_test.jpg', content_type: 'image/jpeg')
    end
  end
end
