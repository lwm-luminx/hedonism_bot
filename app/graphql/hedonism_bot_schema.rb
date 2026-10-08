# frozen_string_literal: true

class HedonismBotSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader
  use GraphQL::PersistedQueries, compiled_queries: true
  use GraphQL::Tracing::DetailedTrace, redis: Redis.new, limit: 100

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  # Every model exposed through `node` has a matching Types::<Model>Type (PhotoPromise → PhotoPromiseType),
  # except PhotoTake, which the API calls Photo.
  def self.resolve_type(abstract_type, obj, ctx)
    return Types::PhotoType if obj.is_a?(PhotoTake)

    "Types::#{obj.class.name}Type".safe_constantize || raise("Unexpected object type: #{obj.class}")
  end

  # Limit the size of incoming queries:
  max_query_string_tokens(5000)

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a global ID, find the object, but only when it belongs to the request's photographer.
  def self.object_from_id(global_id, query_ctx)
    photographer = query_ctx[:photographer]
    object = GlobalID::Locator.locate(global_id) if photographer
    object if object.respond_to?(:owner_photographer_id) && object.owner_photographer_id == photographer.id
  rescue ActiveRecord::RecordNotFound, NameError
    nil
  end

  def self.detailed_trace?(query)
    Rails.env.development?
  end
end
