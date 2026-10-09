namespace :photography do
  desc "Issue a read-only audience grant; prints its credential once"
  task :grant, [ :photographer_id, :audience_id ] => :environment do |_task, args|
    photographer = Photographer.find(args.fetch(:photographer_id))
    grant, token = PhotographyGrant.issue!(photographer: photographer, audience_id: args.fetch(:audience_id))
    puts "Grant: #{grant.id}"
    puts "Access token (save now): #{token}"
  end

  desc "Explicitly share one logical Photo with an audience grant"
  task :publish, [ :grant_id, :photo_id ] => :environment do |_task, args|
    grant = PhotographyGrant.find(args.fetch(:grant_id))
    grant.photography_publications.find_or_create_by!(photo: Photo.find(args.fetch(:photo_id)))
  end

  desc "Remove a shared Photo from an audience grant"
  task :unpublish, [ :grant_id, :photo_id ] => :environment do |_task, args|
    PhotographyGrant.find(args.fetch(:grant_id)).photography_publications.where(photo_id: args.fetch(:photo_id)).destroy_all
  end

  desc "Revoke an audience grant immediately"
  task :revoke, [ :grant_id ] => :environment do |_task, args|
    PhotographyGrant.find(args.fetch(:grant_id)).update!(revoked_at: Time.current)
  end
end
