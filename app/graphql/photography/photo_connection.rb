module Photography
  # Pages a grant's publications by keyset on (published_at, photo_key), so a cursor stays valid while photos are
  # published or removed around it; offsets would skip or repeat. Cursors are opaque to AudienceKit. Forward only.
  class PhotoConnection < GraphQL::Pagination::Connection
    SEPARATOR = "|"

    def nodes
      load_page
      @nodes
    end

    def has_next_page
      load_page
      @has_next_page
    end

    def has_previous_page
      false
    end

    def cursor_for(item)
      encode("#{item.published_at.utc.iso8601(6)}#{SEPARATOR}#{item.id}")
    end

    private

    def load_page
      return if defined?(@nodes)

      limit = first
      scope = items.reorder(:published_at, :photo_key)
      scope = scope.where("(photography_publications.published_at, photography_publications.photo_key) > (?, ?)", *after_keys) if after
      rows = scope.limit(limit + 1).to_a
      @has_next_page = rows.size > limit
      @nodes = rows.first(limit).map { |publication| PublishedPhoto.new(publication) }
    end

    def after_keys
      published_at, key = decode(after).split(SEPARATOR, 2)
      time = Time.iso8601(published_at.to_s)
      raise GraphQL::ExecutionError, "Invalid photo cursor" unless key&.match?(/\A[0-9a-f-]{36}\z/i)

      [ time, key ]
    rescue ArgumentError
      raise GraphQL::ExecutionError, "Invalid photo cursor"
    end
  end
end
