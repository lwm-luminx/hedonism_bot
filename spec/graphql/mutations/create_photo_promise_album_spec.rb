require 'rails_helper'

RSpec.describe Mutations::CreatePhotoPromise, type: :graphql do
  let(:photographer) { create(:photographer) }

  it "puts uploads in the named album" do
    execute_graphql(<<~GQL, context: uploader_context(photographer))
      mutation { createPhotoPromise(albumName: "SD 2026-10-07") { promise { album { id } } } }
    GQL

    expect(PhotoPromise.last.album.name).to eq("SD 2026-10-07")
  end
end
