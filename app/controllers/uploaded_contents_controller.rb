class UploadedContentsController < ApplicationController
  skip_before_action :set_photographer
  skip_forgery_protection

  def create
    account = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return head :unauthorized unless account

    hashes = params[:hashes]
    unless hashes.is_a?(Array) && hashes.size <= 200 && hashes.all? { |hash| hash.is_a?(String) && hash.match?(/\A[A-Za-z0-9+\/]{43}=\z/) }
      return render json: { error: "Provide up to 200 Base64 SHA-256 hashes" }, status: :bad_request
    end

    digests = hashes.map { |hash| Base64.strict_decode64(hash) }
    files = PhotoPromiseFile.joins(:photo_promise)
      .where(photo_promises: { photographer_id: account.photographer_id }, status: "success", image_hash: digests)
      .where.not(photo_take_id: nil)
    uploaded = files.select(&:uploaded?).map { |file| Base64.strict_encode64(file.image_hash) }.uniq
    legacy_takes = PhotoTake.with_photographer(account.photographer).where(image_hash: digests).with_attached_raw_image
    legacy_takes.each do |take|
      next unless take.raw_image.attached? && take.raw_image.blob.service.exist?(take.raw_image.blob.key)

      uploaded << Base64.strict_encode64(take.image_hash)
    end
    response.headers["Cache-Control"] = "no-store"
    render json: { hashes: uploaded.uniq }
  end
end
