FactoryBot.define do
  factory :image do
    transient {
      image_url { Faker::LoremFlickr.image }
    }

    mime_type { "image/jpeg" }
    source_url { image_url }
    cdn_url { URI.for "https", nil, "cdn.app.com", 443, nil, "cdn_image", nil, URI.to_query(url: image_url), nil }
    content_hash { Faker::Crypto.sha256 }
  end
end
