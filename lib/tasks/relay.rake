namespace :relay do
  desc "Perform a Relay compilation"
  task compile: :environment do
    sh "bun run relay:compile"
  end
end
