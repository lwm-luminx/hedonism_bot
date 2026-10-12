module Photography
  # What a grant's publication looks like to AudienceKit: the photo as it is now, or a tombstone when it has been
  # unpublished, deleted, moved to another photographer or has no processed take left.
  class PublishedPhoto
    attr_reader :publication

    def initialize(publication)
      @publication = publication
    end

    def id
      publication.photo_key
    end

    def published_at
      publication.published_at
    end

    def updated_at
      publication.updated_at
    end

    def photo
      publication.photo
    end

    def removed?
      publication.removed? || photo.nil? || photo.owner_photographer_id != publication.photography_grant.photographer_id ||
        processed_takes.empty?
    end

    def processed_takes
      photo ? photo.processed_takes : []
    end

    def take_count
      removed? ? 0 : processed_takes.size
    end

    # A stable link (PreviewsController) rather than the storage URL, which expires within minutes.
    def preview_url
      return if removed?

      take = processed_takes.find { |candidate| candidate.images_attachments.any? { |image| image.blob.content_type == "image/jpeg" } }
      return unless take

      Rails.application.routes.url_helpers.preview_url(take, host: publication.photography_grant.photographer.host,
                                                             protocol: "https")
    end
  end
end
