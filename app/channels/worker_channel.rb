class WorkerChannel < ActionCable::Channel::Base
  CAPTION_UPDATE = <<~GRAPHQL.freeze
    mutation WorkerCaption($id: ID!, $caption: String!, $description: String!) {
      updatePhotoCaption(id: $id, caption: $caption, description: $description) { photo { id } }
    }
  GRAPHQL
  FACE_UPDATE = <<~GRAPHQL.freeze
    mutation WorkerFaces($id: ID!, $faces: [FaceDataInput!]!) {
      updatePhotoFace(id: $id, faces: $faces) { photo { id } }
    }
  GRAPHQL

  def subscribed
    reject unless params["protocol"] == 1 && connection.authorized?
  end

  def claim(_data)
    return unless authorized!

    # At most one live claim per socket, including a retransmitted claim request.
    work = @claim && PhotoInferenceWork.find_by(id: @claim.id)
    work = PhotoInferenceWork.claim(service_account) unless work&.leased_to?(service_account, @claim.lease_token)
    @claim = work
    transmit(work ? { type: "work", id: work.id, task: work.task, photo_id: work.photo_take.to_gid_param,
                      lease_token: work.lease_token } : { type: "idle" })
  end

  def heartbeat(data)
    with_lease(data) do |work|
      work.update!(lease_expires_at: [ 2.minutes.from_now, work.deadline_at ].min)
      transmit({ type: "renewed", id: work.id })
    end
  end

  def complete(data)
    data = data.deep_stringify_keys
    return unless authorized!
    return reject_payload if data.to_json.bytesize > 1.megabyte || !data["result"].is_a?(Hash)

    work = PhotoInferenceWork.where(photographer: service_account.photographer).find_by(id: data["id"])
    return reject_payload unless work

    work.with_lock do
      if work.state == "completed" && work.service_account_id == service_account.id && work.lease_token == data["lease_token"]
        return transmit({ type: "completed", id: work.id })
      end
      return reject_payload unless work.leased_to?(service_account, data["lease_token"])

      apply_result!(work, data.fetch("result"))
      work.update!(state: "completed")
      transmit({ type: "completed", id: work.id })
    end
  rescue KeyError, GraphQL::ExecutionError, ActiveRecord::RecordInvalid
    reject_payload
  end

  def failed(data)
    with_lease(data) do |work|
      work.update!(state: work.attempts >= 3 ? "failed" : "retry", lease_expires_at: 30.seconds.from_now)
      transmit({ type: "failed", id: work.id })
    end
  end

  private

  def authorized!
    return true if connection.authorized?

    connection.close(reason: "unauthorized", reconnect: false)
    false
  end

  def reject_payload
    transmit({ type: "lease_rejected" })
  end

  def with_lease(data)
    return unless authorized!

    work = PhotoInferenceWork.where(photographer: service_account.photographer).find_by(id: data["id"])
    return reject_payload unless work

    work.with_lock do
      return reject_payload unless work.leased_to?(service_account, data["lease_token"])

      yield work
    end
  end

  def apply_result!(work, result)
    # Results and completion commit under the same lease lock; stale workers cannot write.
    variables = if work.face_task?
      { "id" => work.photo_take.to_gid_param, "faces" => result.fetch("faceObjects") }
    else
      { "id" => work.photo_take.to_gid_param, "caption" => result.fetch("caption"), "description" => result.fetch("description") }
    end
    response = HedonismBotSchema.execute(work.face_task? ? FACE_UPDATE : CAPTION_UPDATE, variables: variables,
                                        context: { photographer: work.photographer })
    raise GraphQL::ExecutionError, "Result rejected" if response["errors"]
  end
end
