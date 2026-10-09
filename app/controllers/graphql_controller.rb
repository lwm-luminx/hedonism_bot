# frozen_string_literal: true

class GraphqlController < ApplicationController
  include ActionController::Live

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # Service accounts (bearer tokens) don't carry a CSRF token, so drop the session rather than fail.
  protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query] #: String?
    operation_name = params[:operationName]
    extensions = params[:extensions]
    context = {
      photographer: photographer,
      current_user: current_user,
      service_account: @service_account,
      extensions: extensions
    }
    result = HedonismBotSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # A bearer token (service account) picks the photographer; otherwise the host does.
  def resolve_photographer
    token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
    return super unless token

    @service_account = ServiceAccount.authenticate(token)
    return @service_account.photographer if @service_account

    render json: { errors: [ { message: "Invalid service account token" } ] }, status: :unauthorized
    nil
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace&.join("\n")

    render json: { errors: [ { message: e.message, backtrace: e.backtrace } ], data: Hash.new }, status: 500
  end
end
