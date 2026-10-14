require "rails_helper"

RSpec.describe FacebookDataDeletionJob do
  before { stub_const("FACEBOOK_APP_ID", "app-123") }

  def accept(user)
    DataDeletionRequest.accept!({ "user_id" => user.facebook_id }, "payload-#{user.id}")
  end

  def biometric_fixture
    user = User.create!(facebook_id: "123")
    other = User.create!(facebook_id: "456")
    photographer = Photographer.create!(name: "Gallery", subdomain: "gallery")
    PhotographerAdmin.create!(user: user, photographer: photographer, role: "admin")
    PhotographerAdmin.create!(user: other, photographer: photographer, role: "admin")
    album = Album.create!(name: "Shared", photographer: photographer)
    photo = Photo.create!(album: album)
    take = PhotoTake.create!(photo: photo, original_filename: "test.jpg", content_type: "image/jpeg", file_size_bytes: 10,
                             facial_metadata: [ { embedding: [ 1 ] } ])
    face = Face.create!(photographer: photographer, user_id: user.id, arc_face_embedding: [ 1.0 ] * 512)
    photo_face = PhotoFace.create!(photo_take: take, face: face, arc_face_embedding: [ 1.0 ] * 512)
    photo_face.face_image.attach(io: StringIO.new("image"), filename: "face.jpg", content_type: "image/jpeg")
    blob = photo_face.face_image.blob
    service = blob.service
    key = blob.key
    receipt = accept(user)

    { user: user, other: other, photographer: photographer, photo: photo, take: take,
      face: face, photo_face: photo_face, service: service, key: key, receipt: receipt }
  end

  def legacy_fixture
    row = ->(table, attributes) { Class.new(ApplicationRecord) { self.table_name = table }.create!(attributes) }
    user = User.create!(facebook_id: "123")
    other = User.create!(facebook_id: "456")
    audience = row.call("audiences", name: "Shared", subdomain: "shared")
    locale = row.call("locales", audience_id: audience.id)
    location = row.call("locations", google_place_id: "location", google_location: {})
    page = row.call("pages", facebook_id: 111, name: "Page", facebook_graph: {})
    venue = row.call("venues", audience_id: audience.id, locale_id: locale.id, location_id: location.id, page_id: page.id)
    event = row.call("events", venue_id: venue.id, facebook_id: 222, facebook_graph: {})
    tribe = row.call("tribes", audience_id: audience.id, name: "Tribe", description: "Shared")
    ticket_type = row.call("ticket_types", event_id: event.id, provider: "test", provider_id: "ticket")
    session = row.call("sessions", audience_id: audience.id, user_id: user.id)
    row.call("user_locations", session_id: session.id, location_id: location.id)
    friendship = row.call("friendships", friend_low_id: user.id, friend_high_id: other.id)
    row.call("friendship_links", friendship_id: friendship.id, user_id: other.id, friend_id: user.id)
    {
      "audience_users" => { audience_id: audience.id, facebook_id: 123 },
      "audience_admins" => { audience_id: audience.id, role: "admin" },
      "tribe_users" => { tribe_id: tribe.id },
      "user_likes" => { page_id: page.id },
      "user_rsvps" => { event_id: event.id, state: "going" },
      "reviews" => { page_id: page.id, content: "Personal" },
      "pings" => { locale_id: locale.id },
      "venue_messages" => { venue_id: venue.id, message: "Personal" },
      "user_pages" => { page_id: page.id, facebook_token: "personal-token" },
      "tickets" => { ticket_type_id: ticket_type.id, quantity: 1 }
    }.each { |table, attrs| row.call(table, attrs.merge(user_id: user.id)) }
    receipt = accept(user)
    { user: user, other: other, session: session, receipt: receipt,
      shared: [ audience, locale, location, page, venue, event, tribe, ticket_type ] }
  end

  def blob_fixture
    user = User.create!(facebook_id: "123")
    image = Image.create!(source_url: "https://example.com/profile", cdn_url: "https://example.com/cache",
                          content_hash: "digest", mime_type: "image/jpeg")
    image.image_file.attach(io: StringIO.new("profile"), filename: "profile.jpg", content_type: "image/jpeg")
    blob = image.image_file.blob
    key = blob.key
    variant = ActiveStorage::VariantRecord.create!(blob: blob, variation_digest: "test-variant")
    variant.image.attach(io: StringIO.new("variant"), filename: "small.jpg", content_type: "image/jpeg")
    variant_key = variant.image.blob.key
    user.update!(image_id: image.id)
    receipt = accept(user)
    { user: user, image: image, blob: blob, key: key, variant_key: variant_key, receipt: receipt }
  end

  context "with personal records and biometric derivatives" do
    let(:records) { biometric_fixture }
    let(:receipt) { records.fetch(:receipt) }

    before { described_class.perform_now(receipt.id) }

    { user: User, face: Face, photo_face: PhotoFace }.each do |name, model|
      it "deletes the #{name} record" do
        expect(model.exists?(records.fetch(name).id)).to be(false)
      end
    end

    { other: User, photographer: Photographer, photo: Photo }.each do |name, model|
      it "preserves the #{name} record" do
        expect(model.exists?(records.fetch(name).id)).to be(true)
      end
    end

    it "preserves another administrator's grant" do
      expect(PhotographerAdmin.where(user_id: records.fetch(:other).id).count).to eq(1)
    end

    it "clears facial metadata and disables processing" do
      expect(records.fetch(:take).reload).to have_attributes(face_processing_disabled: true, facial_metadata: nil)
    end

    it "purges the face crop" do
      expect(records.fetch(:service).exist?(records.fetch(:key))).to be(false)
    end

    it "waits for review before completion" do
      expect(receipt.reload).to have_attributes(status: "needs_attention", completed_at: nil)
    end

    it "retains the subject in restricted review context" do
      expect(receipt.reload.review_context.fetch("user_id")).to eq(records.fetch(:user).id)
    end

    it "encrypts the review context" do
      expect(receipt.reload.encrypted_review_context).not_to include(records.fetch(:user).id)
    end

    it "rejects delayed face updates" do
      expect(records.fetch(:take).update_faces([])).to be(false)
    end

    context "when operator review is complete" do
      before { receipt.reload.confirm_review! }

      it "completes and erases review context" do
        expect(receipt.reload).to have_attributes(status: "completed", encrypted_review_context: nil)
      end

      it "does not delete additional users on retry" do
        expect { described_class.perform_now(receipt.id) }.not_to change(User, :count)
      end
    end
  end

  context "with every remaining user foreign key" do
    let(:records) { legacy_fixture }

    before { described_class.perform_now(records.fetch(:receipt).id) }

    it "finishes local cleanup" do
      expect(records.fetch(:receipt).reload.local_deleted_at).to be_present
    end

    it "deletes the subject" do
      expect(User.exists?(records.fetch(:user).id)).to be(false)
    end

    it "preserves the other user" do
      expect(User.exists?(records.fetch(:other).id)).to be(true)
    end

    it "removes inbound friendship links" do
      expect(FriendshipLink.exists?(friend_id: records.fetch(:user).id)).to be(false)
    end

    it "removes session locations" do
      expect(UserLocation.exists?(session_id: records.fetch(:session).id)).to be(false)
    end

    it "preserves shared data" do
      expect(records.fetch(:shared).map { |record| record.class.exists?(record.id) }).to all(be(true))
    end
  end

  context "when blob deletion fails" do
    let(:records) { blob_fixture }
    let(:receipt) { records.fetch(:receipt) }

    before do
      allow(records.fetch(:blob).service).to receive(:delete).and_raise(IOError)
      described_class.perform_now(receipt.id)
    end

    it "schedules a retry without claiming completion" do
      expect(receipt.reload).to have_attributes(status: "retrying", completed_at: nil)
    end

    it "retains the user for retryable cleanup" do
      expect(User.exists?(records.fetch(:user).id)).to be(true)
    end

    context "when storage recovers" do
      before do
        allow(records.fetch(:blob).service).to receive(:delete).and_call_original
        described_class.perform_now(receipt.id)
      end

      it "finishes local cleanup" do
        expect(receipt.reload.local_deleted_at).to be_present
      end

      %i[key variant_key].each do |key|
        it "purges the #{key} object" do
          expect(records.fetch(:blob).service.exist?(records.fetch(key))).to be(false)
        end
      end

      { image: Image, user: User }.each do |name, model|
        it "deletes the #{name} record" do
          expect(model.exists?(records.fetch(name).id)).to be(false)
        end
      end
    end
  end

  context "when the cleanup service fails" do
    let(:user) { User.create!(facebook_id: "123") }
    let(:receipt) { accept(user) }
    let(:service) { instance_double(UserDataDeletionService) }

    before do
      allow(UserDataDeletionService).to receive(:new).with(have_attributes(id: receipt.id)).and_return(service)
      allow(service).to receive(:call).and_raise(StandardError)
      described_class.perform_now(receipt.id)
    end

    it "schedules a retry without claiming completion" do
      expect(receipt.reload).to have_attributes(status: "retrying", completed_at: nil)
    end

    it "keeps access blocked" do
      expect(user.reload.deletion_pending_at).to be_present
    end

    it "dispatches due work again" do
      receipt.update!(next_attempt_at: 1.minute.ago)
      allow(described_class).to receive(:perform_later)
      DispatchDataDeletionsJob.perform_now
      expect(described_class).to have_received(:perform_later).with(receipt.id)
    end
  end

  context "with coalesced deliveries" do
    let(:user) { User.create!(facebook_id: "123") }
    let(:receipt) { accept(user) }
    let(:coalesced) { DataDeletionRequest.accept!({ "user_id" => "123" }, "coalesced-payload") }

    before { receipt }

    it "reuses the active receipt" do
      expect(coalesced.id).to eq(receipt.id)
    end

    context "with completed deletion and fresh authorization" do
      let(:fresh) { User.from_facebook_graph({ "id" => "123", "first_name" => "New" }) }

      before do
        coalesced
        described_class.perform_now(receipt.id)
        receipt.reload.confirm_review!
        fresh
      end

      it "creates a new account" do
        expect(fresh.id).not_to eq(user.id)
      end

      it "returns the original receipt for a replay" do
        expect(DataDeletionRequest.accept!({ "user_id" => "123" }, "payload-#{user.id}").id).to eq(receipt.id)
      end

      it "returns the original receipt for a coalesced replay" do
        expect(DataDeletionRequest.accept!({ "user_id" => "123" }, "coalesced-payload").id).to eq(receipt.id)
      end

      it "does not block the fresh account on replays" do
        DataDeletionRequest.accept!({ "user_id" => "123" }, "payload-#{user.id}")
        DataDeletionRequest.accept!({ "user_id" => "123" }, "coalesced-payload")
        expect(fresh.reload.deletion_pending_at).to be_nil
      end

      it "creates a new receipt for a new deletion request" do
        expect(DataDeletionRequest.accept!({ "user_id" => "123" }, "new-payload").id).not_to eq(receipt.id)
      end

      it "blocks the fresh account for a new deletion request" do
        DataDeletionRequest.accept!({ "user_id" => "123" }, "new-payload")
        expect(fresh.reload.deletion_pending_at).to be_present
      end
    end
  end
end
