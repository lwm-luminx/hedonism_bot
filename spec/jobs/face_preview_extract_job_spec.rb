require "rails_helper"

RSpec.describe FacePreviewExtractJob, type: :job do
  let(:photo) { create(:photo_face) }

  it "extracts a preview from a real image" do
    # The repository test.jpg is an empty placeholder, so supply an actual image for Vips.
    photo.photo_take.images.purge
    jpeg = Vips::Image.black(20, 20).write_to_buffer(".jpg")
    photo.photo_take.images.attach(io: StringIO.new(jpeg), filename: "test.jpg", content_type: "image/jpeg")
    described_class.perform_now(photo)
    expect(photo.reload.face_image.blob.byte_size).to be_positive
  end

  it "does not recreate a preview for an excluded take" do
    photo.photo_take.update!(face_processing_disabled: true)
    photo.face_image.purge
    described_class.perform_now(photo)
    expect(photo.reload.face_image).not_to be_attached
  end
end
