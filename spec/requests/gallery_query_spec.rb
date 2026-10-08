require 'rails_helper'

# The query the gallery home page sends first; if it errors the page has nothing to show.
RSpec.describe "Gallery query", type: :request do
  let(:album) { create(:album, photographer: photographer("luminx")) }
  let!(:face) { face_in(album) }
  let!(:other_face) { face_in(create(:album, photographer: photographer("luminx"))) }
  let!(:foreign_face) { face_in(create(:album, photographer: photographer("sam"))) }

  def photographer(subdomain)
    Photographer.find_or_create_by!(subdomain: subdomain) { |p| p.name = subdomain.capitalize }
  end

  def face_in(album)
    take = PhotoTake.create!(photo: Photo.create!(album: album), original_filename: "a.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    create(:face, photographer: album.photographer).tap { |face| PhotoFace.create!(face: face, photo_take: take) }
  end

  def run(variables = {})
    query = <<~GRAPHQL
      query($faceId: ID, $folderId: ID) {
        folders(faceId: $faceId) { nodes { id name photoCount } }
        faces(folderId: $folderId) { nodes { id thumbnailUrl photoCount } }
      }
    GRAPHQL
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: { "Host" => "luminx.lumiere.host" }
    JSON.parse(response.body)
  end

  def face_ids(body)
    body.dig("data", "faces", "nodes").map { |n| n["id"] }
  end

  it "returns the photographer's folders and faces without errors", :aggregate_failures do
    body = run

    expect(response).to have_http_status(:ok)
    expect(body["errors"]).to be_nil
    expect(body.dig("data", "folders", "nodes").size).to eq(2)
    expect(face_ids(body)).to contain_exactly(face.to_gid_param, other_face.to_gid_param)
  end

  it "narrows faces to a folder" do
    expect(face_ids(run(folderId: album.to_gid_param))).to eq([ face.to_gid_param ])
  end

  it "returns no faces for another photographer's folder" do
    expect(face_ids(run(folderId: foreign_face.photo_takes.first.photo.album.to_gid_param))).to eq([])
  end
end
