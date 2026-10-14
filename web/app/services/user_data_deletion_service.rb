class UserDataDeletionService
  def initialize(receipt)
    @receipt = receipt
  end

  def call
    delete_local_data unless @receipt.local_deleted_at
    purge_objects
  end

  private

  def delete_local_data
    PrivacyLock.biometric do
      user = User.lock.find_by(id: @receipt.user_id)
      if user
        erase_faces(user)
        erase_profile_image(user)
        session_ids = Session.where(user_id: user.id).pluck(:id)
        delete_rows("user_locations", session_id: session_ids)
        friendships = Friendship.where(friend_low_id: user.id).or(Friendship.where(friend_high_id: user.id)).pluck(:id)
        delete_rows("friendship_links", friendship_id: friendships)
        delete_rows("friendship_links", friend_id: user.id)
        delete_rows("friendship_links", user_id: user.id)
        delete_rows("friendships", id: friendships)
        # Explicitly preserve shared organizations and content. Do not invoke User's legacy callbacks.
        %w[sessions audience_users audience_admins photographer_admins tribe_users user_likes
           user_rsvps reviews pings venue_messages user_pages tickets].each do |table|
          delete_rows(table, user_id: user.id)
        end
        user.delete
      end
      @receipt.update!(local_deleted_at: Time.current, user_id: nil)
    end
  end

  def erase_faces(user)
    face_ids = Face.where(user_id: user.id).pluck(:id)
    take_ids = PhotoFace.where(face_id: face_ids).pluck(:photo_take_id).uniq
    @receipt.update!(review_context: (@receipt.review_context || {}).merge("face_ids" => face_ids, "photo_take_ids" => take_ids))
    # Conservatively remove all face derivatives on affected takes: metadata lacks stable region IDs.
    takes = PhotoTake.where(id: take_ids)
    takes.update_all(face_processing_disabled: true, facial_metadata: nil)
    affected = PhotoFace.where(photo_take_id: take_ids)
    affected.find_each { |face| detach_for_purge(face.face_image) }
    other_face_ids = affected.where.not(face_id: nil).pluck(:face_id).uniq - face_ids
    affected.delete_all
    # Aggregates may include erased per-photo embeddings; discard them so clustering can rebuild
    # only from the remaining eligible inputs. Preserve other users' identity rows.
    Face.where(id: other_face_ids).update_all(arc_face_embedding: nil)
    Face.where(id: face_ids).delete_all
  end

  def erase_profile_image(user)
    return unless user.image_id
    image = Image.find_by(id: user.image_id)
    user.update_columns(image_id: nil)
    return unless image
    @receipt.update!(review_context: (@receipt.review_context || {}).merge("profile_source_url" => image.source_url, "profile_cdn_url" => image.cdn_url))
    references = { "users" => %w[image_id], "pages" => %w[image_id cover_image_id],
                   "events" => %w[cover_image_id], "event_templates" => %w[cover_image_id],
                   "locations" => %w[image_id], "tracks" => %w[image_id waveform_image_id] }
    if references.any? { |table, columns| columns.any? { |column| table_model(table).where(column => image.id).exists? } }
      add_review("shared_profile_image")
      return
    end
    # source_url/cdn_url may refer to legacy external caches; review remains mandatory.
    detach_for_purge(image.image_file)
    image.delete
  end

  def detach_for_purge(attachment)
    return unless attachment.attached?
    blob = attachment.blob
    attachment.detach
    if blob.attachments.exists?
      add_review("shared_personal_blob")
    else
      # Tracked variants have independent blob keys, unlike legacy variants under a key prefix.
      blob.variant_records.find_each do |variant|
        detach_for_purge(variant.image)
        variant.destroy!
      end
      detach_for_purge(blob.preview_image) if blob.preview_image.attached?
      manifest = @receipt.cleanup_manifest + [ { "blob_id" => blob.id, "service_name" => blob.service_name,
                                               "key" => blob.key, "image" => blob.image? } ]
      @receipt.update!(cleanup_manifest: manifest.uniq { |entry| entry["blob_id"] })
    end
  end

  def purge_objects
    @receipt.cleanup_manifest.each do |entry|
      blob = ActiveStorage::Blob.find_by(id: entry.fetch("blob_id"))
      if blob&.attachments&.exists?
        add_review("shared_personal_blob")
        next
      end
      # Delete using the saved service/key even if a previous attempt removed the blob row.
      service = ActiveStorage::Blob.services.fetch(entry.fetch("service_name"))
      service.delete(entry.fetch("key"))
      service.delete_prefixed("variants/#{entry.fetch('key')}/") if entry["image"]
      blob&.purge
    end
    @receipt.update!(cleanup_manifest: [])
  end

  def add_review(reason)
    @receipt.update!(review_reasons: (@receipt.review_reasons + [ reason ]).uniq)
  end

  def delete_rows(table, conditions)
    table_model(table).where(conditions).delete_all
  end

  # Several legacy tables have no usable AR model. Keep deletion predicates explicit and bound.
  def table_model(table)
    @table_models ||= {}
    @table_models[table] ||= Class.new(ApplicationRecord) { self.table_name = table }
  end
end
