# Per-request state: the photographer (tenant) the request's host or service account resolved to.
class Current < ActiveSupport::CurrentAttributes
  attribute :photographer
end
