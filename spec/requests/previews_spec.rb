require "rails_helper"

# The stable preview links the photography contract hands to AudienceKit.
RSpec.describe "Photo previews", type: :request do
  let(:photographer) { Photographer.create!(name: "Sam", subdomain: "sam", active: true) }
  let(:album) { Album.create!(photographer: photographer, name: "Shared") }
  let(:photo) { Photo.create!(album: album) }
  let(:take) do
    PhotoTake.create!(photo: photo, status: "processed", original_filename: "test.jpg", content_type: "image/jpeg", file_size_bytes: 10).tap do |take|
      take.images.attach(io: Rails.root.join("spec/fixtures/test.jpg").open, filename: "test.jpg", content_type: "image/jpeg")
    end
  end
  let(:grant) { PhotographyGrant.issue!(photographer: photographer, audience_id: SecureRandom.uuid).first }

  def fetch(id = take.id, host: "sam.lumiere.host")
    get "/previews/#{id}", headers: { "Host" => host }
  end

  it "redirects a published take to its current JPEG, publicly cacheable for a minute" do
    grant.publish!(photo)
    fetch
    expect(response).to have_http_status(:found)
    expect(response.location).to start_with("http://sam.lumiere.host/rails/active_storage/disk/").and end_with("/test.jpg")
    expect(response.headers["Cache-Control"]).to include("public").and include("max-age=60")
  end

  it "is not found before the photo is shared, or once it is unpublished" do
    fetch
    expect(response).to have_http_status(:not_found)
    grant.publish!(photo)
    grant.unpublish!(photo)
    fetch
    expect(response).to have_http_status(:not_found)
  end

  it "is not found once the grant is revoked or expired" do
    grant.publish!(photo)
    grant.update!(revoked_at: Time.current)
    fetch
    expect(response).to have_http_status(:not_found)
    grant.update!(revoked_at: nil, expires_at: 1.minute.ago)
    fetch
    expect(response).to have_http_status(:not_found)
  end

  it "serves only the host's own photographer" do
    grant.publish!(photo)
    Photographer.create!(name: "Alex", subdomain: "alex", active: true)
    fetch(host: "alex.lumiere.host")
    expect(response).to have_http_status(:not_found)
  end

  it "is not found for takes without a JPEG or unknown ids" do
    grant.publish!(photo)
    take.images.each(&:purge)
    fetch
    expect(response).to have_http_status(:not_found)
    fetch(SecureRandom.uuid)
    expect(response).to have_http_status(:not_found)
  end
end
