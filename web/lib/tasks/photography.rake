namespace :photography do
  desc "Issue a read-only audience grant, optionally expiring (ISO 8601); prints its credential once"
  task :grant, [ :photographer_id, :audience_id, :expires_at ] => :environment do |_task, args|
    photographer = Photographer.find(args.fetch(:photographer_id))
    expires_at = args[:expires_at].present? ? Time.zone.iso8601(args[:expires_at]) : nil
    grant, token = PhotographyGrant.issue!(photographer: photographer, audience_id: args.fetch(:audience_id), expires_at: expires_at)
    puts "Grant: #{grant.id}#{" (expires #{grant.expires_at.iso8601})" if grant.expires_at}"
    puts "Access token (save now): #{token}"
  end

  desc "Explicitly share one logical Photo with an audience grant"
  task :publish, [ :grant_id, :photo_id ] => :environment do |_task, args|
    PhotographyGrant.find(args.fetch(:grant_id)).publish!(Photo.find(args.fetch(:photo_id)))
  end

  desc "Remove a shared Photo from an audience grant; AudienceKit sees a tombstone"
  task :unpublish, [ :grant_id, :photo_id ] => :environment do |_task, args|
    PhotographyGrant.find(args.fetch(:grant_id)).unpublish!(Photo.find(args.fetch(:photo_id)))
  end

  desc "Revoke an audience grant immediately"
  task :revoke, [ :grant_id ] => :environment do |_task, args|
    PhotographyGrant.find(args.fetch(:grant_id)).update!(revoked_at: Time.current)
  end
end
