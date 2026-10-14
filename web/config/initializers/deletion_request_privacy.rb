# Rails filters query/route params, but normally prints capability tokens in the request path.
module DeletionRequestPrivacy
  def filtered_path
    super.sub(%r{\A/privacy/deletion/[^/?]+}, "/privacy/deletion/[FILTERED]")
  end
end
ActionDispatch::Request.prepend(DeletionRequestPrivacy)
