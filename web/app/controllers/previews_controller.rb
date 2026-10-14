# GET /previews/:id on the photographer's host: the current JPEG preview of a take whose photo is shared with an
# AudienceKit audience. The link is stable and public (AudienceKit hands it to apps), and redirects to the stored
# image, whose URL expires within minutes. Nothing else about the take is revealed.
class PreviewsController < ApplicationController
  include ActiveStorage::SetCurrent

  REDIRECT_TTL = 1.minute

  def show
    take = PhotoTake.processed.with_photographer(photographer).includes(images_attachments: :blob).find_by(id: params[:id])
    url = take&.photo&.published? && take.preview_url
    return head :not_found unless url

    expires_in REDIRECT_TTL, public: true
    redirect_to url, allow_other_host: true, status: :found
  end
end
