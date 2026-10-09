require "rails_helper"

RSpec.describe Mutations::DeleteAlbum, type: :graphql do
  let(:photographer) { create(:photographer) }
  let(:album) { Album.create!(photographer: photographer, name: "Pride 2026") }
  let!(:take) { create_take_with_files(album) }
  let(:admin) { create(:user).tap { |user| PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin") } }
  let(:query) { "mutation($id: ID!) { deleteAlbum(id: $id) { deletedId } }" }

  def delete_as(user, tenant: photographer)
    execute_graphql(query, variables: { id: album.to_gid_param }, context: { photographer: tenant, current_user: user })
  end

  it "deletes the album and its photos", :aggregate_failures do
    photo_id = take.photo_id
    delete_as(admin)
    expect(data.dig("deleteAlbum", "deletedId")).to eq(album.to_gid_param)
    expect([ Album.exists?(album.id), Photo.exists?(photo_id), PhotoTake.exists?(take.id) ]).to eq([ false, false, false ])
  end

  it "detaches upload promises" do
    promise = PhotoPromise.create!(photographer: photographer, album: album)
    delete_as(admin)
    expect(promise.reload.album_id).to be_nil
  end

  it "requires an admin", :aggregate_failures do
    delete_as(create(:user))

    expect(response_errors).to be_present
    expect(Album.exists?(album.id)).to be(true)
  end

  it "rejects albums belonging to another tenant", :aggregate_failures do
    delete_as(create(:user, god_mode: true), tenant: create(:photographer, subdomain: "other"))

    expect(response_errors).to be_present
    expect(Album.exists?(album.id)).to be(true)
  end
end
