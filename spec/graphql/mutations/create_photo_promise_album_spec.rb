require 'rails_helper'

RSpec.describe Mutations::CreatePhotoPromise, type: :graphql do
  let(:photographer) { create(:photographer) }

  it "puts uploads in the named album" do
    execute_graphql(<<~GQL, context: { photographer: photographer })
      mutation { createPhotoPromise(albumName: "SD 2026-10-07") { promise { album { id } } } }
    GQL

    expect(PhotoPromise.last.album.name).to eq("SD 2026-10-07")
  end

  describe "shoot details" do
    let(:details) { { event: "Launch", venue: "The Hall" } }
    let(:query) do
      <<~GQL
        mutation($context: JSON) {
          createPhotoPromise(albumName: "Opening night", uploadContext: $context) { promise { id } }
        }
      GQL
    end

    before { execute_graphql(query, variables: { context: details }, context: { photographer: photographer }) }

    it "persists details on the tenant's album" do
      expect(PhotoPromise.last.album.upload_context).to eq("event" => "Launch", "venue" => "The Hall")
    end

    context "with unsupported metadata" do
      let(:details) { { photographer_id: "other" } }

      it "does not create an upload promise" do
        expect(PhotoPromise.count).to eq(0)
      end

      it "reports invalid details" do
        expect(response_errors.first["message"]).to eq("Invalid shoot details")
      end
    end
  end
end
