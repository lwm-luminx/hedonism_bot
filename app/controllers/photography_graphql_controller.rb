# An isolated read-only contract. Each batch operation carries its own scoped credential.
class PhotographyGraphqlController < ActionController::API
  MAX_BATCH = 20

  def execute
    batch = params[:_json]
    operations = batch || [ params ]
    unless operations.is_a?(Array) && operations.size.between?(1, MAX_BATCH) && operations.all? { |op| valid_operation?(op) }
      return render json: { errors: [ { message: "Invalid photography batch" } ] }, status: :bad_request
    end

    queries = operations.map { |operation| query_options(operation) }
    results = Photography::Schema.multiplex(queries)
    render json: batch ? results : results.first
  end

  private

  def valid_operation?(operation)
    operation.respond_to?(:to_unsafe_h) && operation[:query].is_a?(String) &&
      operation[:variables].respond_to?(:to_unsafe_h) && operation[:extensions].respond_to?(:to_unsafe_h) &&
      (operation[:operationName].nil? || operation[:operationName].is_a?(String))
  end

  def query_options(operation)
    grant = PhotographyGrant.authenticate(operation.dig(:extensions, :accessToken))
    { query: operation[:query], variables: operation[:variables].to_unsafe_h,
      operation_name: operation[:operationName], context: { photography_grant: grant } }
  end
end
