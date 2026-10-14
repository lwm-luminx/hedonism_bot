require 'rails_helper'

RSpec.describe Mutations::ArchiveAlbum, type: :graphql do
  include ActiveJob::TestHelper

  let(:photographer) { create(:photographer) }
  let(:album) { Album.create!(photographer: photographer, name: "Pride 2026") }
  let(:album_id) { album.to_gid_param }

  let(:query) do
    <<~GQL
      mutation($id: ID!) {
        archiveAlbum(id: $id) { album { albumId name transition archivedBytes } }
      }
    GQL
  end

  let(:usage_query) do
    <<~GQL
      { photographer { storage { totalBytes archiveAvailable albums { name originalBytes } } } }
    GQL
  end

  before { create_take_with_files(album) }

  def admin_of(photographer)
    create(:user).tap { |u| PhotographerAdmin.create!(user: u, photographer: photographer, role: "admin") }
  end

  it "enqueues the move" do
    expect {
      execute_graphql(query, variables: { id: album_id }, context: { photographer: photographer, current_user: admin_of(photographer) })
    }.to have_enqueued_job(ArchiveAlbumJob).with(album, "archive")
  end

  it "returns the album as archiving" do
    execute_graphql(query, variables: { id: album_id }, context: { photographer: photographer, current_user: admin_of(photographer) })

    expect(data.dig("archiveAlbum", "album")).to include("albumId" => album_id, "name" => "Pride 2026", "transition" => "ARCHIVING")
  end

  context "with another photographer's album" do
    before do
      other = Photographer.create!(name: "Other", subdomain: "other")
      execute_graphql(query, variables: { id: album_id }, context: { photographer: other, current_user: create(:user, god_mode: true) })
    end

    it "returns an error" do
      expect(response_errors).to be_present
    end

    it "leaves the album alone" do
      expect(album.reload.storage_transition).to be_nil
    end
  end

  [ [ "signed out", nil ], [ "signed in without admin rights", :user ] ].each do |label, user_factory|
    context "when #{label}" do
      before do
        user = user_factory && create(user_factory)
        execute_graphql(query, variables: { id: album_id }, context: { photographer: photographer, current_user: user })
      end

      it "is rejected" do
        expect(response_errors.map { |e| e["message"] }).to include("Admin sign-in required")
      end

      it "leaves the album alone" do
        expect(album.reload.storage_transition).to be_nil
      end
    end
  end

  context "when signed in as an admin of another photographer" do
    before do
      other = Photographer.create!(name: "Other", subdomain: "other")
      execute_graphql(query, variables: { id: album_id }, context: { photographer: photographer, current_user: admin_of(other) })
    end

    it "is rejected" do
      expect(response_errors.map { |e| e["message"] }).to include("Admin sign-in required")
    end
  end

  it "reports usage through the photographer query" do
    execute_graphql(usage_query, context: { photographer: photographer })

    expect(data.dig("photographer", "storage")).to include(
      "totalBytes" => "550", "archiveAvailable" => true,
      "albums" => [ { "name" => "Pride 2026", "originalBytes" => "500" } ]
    )
  end
end
