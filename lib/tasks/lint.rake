require "rubocop/rake_task"

namespace :lint do
  desc "Run ESLint on JavaScript/TypeScript files"
  task eslint: :environment do
    # Execute the npm/yarn command and check the exit status
    system("bun lint")

    # Fail the rake task if eslint reports errors
    exit $?.exitstatus unless $?.success?
  end
end

desc "Run RuboCop and ESLint"
task lint: [ "rubocop:autocorrect", "lint:eslint" ]
