FactoryBot.define do
  factory :image do
    mime_type { "image/jpeg" }
    source_url { "https://example.com/image.jpg" }
    cdn_url { "https://cdn.example.com/image.jpg" }
    content_hash { "hash" }
  end
end
