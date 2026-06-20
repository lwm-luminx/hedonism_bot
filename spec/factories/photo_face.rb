FactoryBot.define do
  factory :photo_face do
    face { create(:face) }
    photo_take { create(:photo_take) }

    confidence { 0.95 }
    arc_face_embedding { (1..512).map { rand(-1.0..1.0) } }
    bounding_box { { "x": 0, "y": 0, "w": 10, "h": 10 } }

    after(:create) do |photo_face|
      test_image = Rails.root.join('spec/fixtures/test.jpg')
      photo_face.photo_take.images.attach(io: File.open(test_image), filename: 'face_test.jpg', content_type: 'image/jpeg')
      photo_face.face_image.attach(io: File.open(test_image), filename: 'face_test.jpg', content_type: 'image/jpeg')
    end
  end
end
