require 'rails_helper'

RSpec.describe Mutations::DeletePhotos, type: :graphql do
  let(:photographer) { create(:photographer) }
  let(:album) { Album.create!(photographer: photographer, name: "Pride 2026") }
  let!(:take) { create_take_with_files(album) }
  let(:admin) { create(:user).tap { |u| PhotographerAdmin.create!(user: u, photographer: photographer, role: "admin") } }

  let(:query) do
    <<~GQL
      mutation($ids: [ID!]!) {
        deletePhotos(ids: $ids) { deletedIds }
      }
    GQL
  end

  def delete_as(user, as_photographer: photographer)
    execute_graphql(query, variables: { ids: [ take.to_gid_param ] }, context: { photographer: as_photographer, current_user: user })
  end

  it "deletes the photo and its now-empty Photo", :aggregate_failures do
    photo = take.photo
    delete_as(admin)

    expect(data.dig("deletePhotos", "deletedIds")).to eq([ take.to_gid_param ])
    expect(PhotoTake.exists?(take.id)).to be(false)
    expect(Photo.exists?(photo.id)).to be(false)
  end

  it "requires an admin" do
    delete_as(create(:user))

    expect(PhotoTake.exists?(take.id)).to be(true)
  end

  it "does not delete another photographer's photo" do
    other = Photographer.create!(name: "Other", subdomain: "other")
    delete_as(create(:user, god_mode: true), as_photographer: other)

    expect(PhotoTake.exists?(take.id)).to be(true)
  end
end
