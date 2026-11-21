# frozen_string_literal: true

# POST /auth/archives/select: the archive a person picked after signing in to Chip or Cogsworth
# (see ArchiveChoice). The signed selection authenticates the request, so this is a session-less API.
class ArchiveChoicesController < ActionController::API
  def create
    body = ArchiveChoice.select(params[:selection], params[:photographer])
    return render json: { error: "Sign-in expired or you no longer administer that archive. Sign in again." }, status: :unauthorized unless body

    response.headers["Cache-Control"] = "no-store"
    render json: body
  end
end
