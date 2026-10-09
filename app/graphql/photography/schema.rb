module Photography
  class Schema < GraphQL::Schema
    query QueryType
    max_query_string_tokens 2000
    max_depth 8
    max_complexity 300
    default_max_page_size 50
    validate_max_errors 10
  end
end
