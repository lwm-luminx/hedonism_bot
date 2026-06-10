module GraphQLHelpers
  # Executes a query or mutation directly against the schema
  def execute_graphql(query, variables: {}, context: {})
    context[:photographer] ||= build(:default_photographer)
    @response = HedonismBotSchema.execute(
      query,
      variables: variables,
      context: context
    )
  end

  def response
    @response
  end

  def response_errors
    response.to_h["errors"]
  end

  def data
    ActiveSupport::HashWithIndifferentAccess.new response.to_h["data"]
  end

  # Shortcut to extract the "data" key from parsed JSON
  def json_data(response)
    response.to_h["data"]
  end

  # Shortcut to extract the "errors" key from parsed JSON
  def json_errors(response)
    response.to_h["errors"]
  end
end
