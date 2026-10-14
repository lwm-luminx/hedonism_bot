module Validate
  def self.run_validate(queries, schema)
    results = queries.map { |query| schema.validate(query) }
    errors = results.flatten

    if errors.empty?

    else
      print_errors(errors)
    end
  end

  def self.print_errors(errors)
    errors.each do |error|
      path = error.path.join(", ")
    end
  end
end

namespace :graphql do
  namespace :queries do
    desc "Validates GraphQL queries against the current schema"
    task validate: [ :environment ] do
      queries_file = "test/fixtures/files/queries.json"
      queries = Oj.load(File.read(queries_file))

      Validate.run_validate(queries, HedonismBotSchema)
    end
  end
end
