require 'rails_helper'

# The query the gallery home page sends first; if it errors the page has nothing to show.
RSpec.describe "Gallery query", type: :request do
  let!(:luminx) { create(:photographer, subdomain: "luminx", name: "Luminx") }
  let!(:sam) { create(:photographer, subdomain: "sam", name: "Sam") }

  let(:query) do
    <<~GRAPHQL
      query($faceId: ID, $folderId: ID) {
        folders(faceId: $faceId) { nodes { id name photoCount } }
        faces(folderId: $folderId) { nodes { id thumbnailUrl photoCount } }
      }
    GRAPHQL
  end

  def face_in(album)
    take = PhotoTake.create!(photo: Photo.create!(album: album), original_filename: "a.jpg", content_type: "image/jpeg", file_size_bytes: 1)
    create(:face, photographer: album.photographer).tap { |face| PhotoFace.create!(face: face, photo_take: take) }
  end

  def run(variables = {})
    post "/graphql", params: { query: query, variables: variables.to_json }, headers: { "Host" => "luminx.hedonism.bot" }
    JSON.parse(response.body)
  end

  let(:album) { create(:album, photographer: luminx) }
  let(:other_album) { create(:album, photographer: luminx) }
  let!(:face) { face_in(album) }
  let!(:other_face) { face_in(other_album) }
  let!(:foreign_face) { face_in(create(:album, photographer: sam)) }

  it "returns the photographer's folders and faces without errors" do
    body = run

    expect(response).to have_http_status(:ok)
    expect(body["errors"]).to be_nil
    expect(body.dig("data", "folders", "nodes").size).to eq(2)
    expect(body.dig("data", "faces", "nodes").map { |n| n["id"] }).to contain_exactly(face.to_gid_param, other_face.to_gid_param)
  end

  it "narrows faces to a folder" do
    body = run(folderId: album.to_gid_param)

    expect(body["errors"]).to be_nil
    expect(body.dig("data", "faces", "nodes").map { |n| n["id"] }).to eq([ face.to_gid_param ])
  end

  it "returns no faces for another photographer's folder" do
    body = run(folderId: foreign_face.photo_takes.first.photo.album.to_gid_param)

    expect(body.dig("data", "faces", "nodes")).to eq([])
  end
end
