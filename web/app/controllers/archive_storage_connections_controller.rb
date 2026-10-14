class ArchiveStorageConnectionsController < ApplicationController
  skip_before_action :set_photographer, only: :update
  skip_forgery_protection only: :update

  def index
    return head :unauthorized unless current_user
    return head :forbidden unless current_user.admin_of?(photographer)

    connections = ArchiveStorageConnection.joins(:service_account)
      .where(service_accounts: { photographer_id: photographer.id, revoked_at: nil })
    response.headers["Cache-Control"] = "no-store"
    render json: { connections: connections.map { |connection| connection.as_json(only: %i[id device_name paths last_seen_at]) } }
  end

  def update
    account = ServiceAccount.authenticate(request.authorization.to_s[/\ABearer (.+)\z/, 1])
    return head :unauthorized unless account

    connection = ArchiveStorageConnection.find_or_initialize_by(service_account: account)
    connection.assign_attributes(device_name: params[:device_name], paths: params[:paths], last_seen_at: Time.current)
    response.headers["Cache-Control"] = "no-store"
    if connection.save
      render json: { id: connection.id }
    else
      render json: { error: connection.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end
end
