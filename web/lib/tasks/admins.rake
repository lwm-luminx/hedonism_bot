namespace :admins do
  find_user = ->(key) { User.find_by(facebook_id: key) || User.find_by!(email_address: key) }

  desc "Make a signed-in user an admin of one photographer: admins:grant[<facebook id or email>,<subdomain>]"
  task :grant, [ :user, :subdomain ] => :environment do |_, args|
    user = find_user.call(args.fetch(:user))
    photographer = Photographer.find_by!(subdomain: args.fetch(:subdomain))
    PhotographerAdmin.find_or_create_by!(user: user, photographer: photographer, role: "admin")
    puts "#{user.name} (#{user.facebook_id}) is now an admin of #{photographer.subdomain}"
  end

  desc "Remove a user's admin rights on one photographer: admins:revoke[<facebook id or email>,<subdomain>]"
  task :revoke, [ :user, :subdomain ] => :environment do |_, args|
    user = find_user.call(args.fetch(:user))
    photographer = Photographer.find_by!(subdomain: args.fetch(:subdomain))
    user.photographer_admins.where(photographer: photographer).destroy_all
    puts "#{user.name} (#{user.facebook_id}) is no longer an admin of #{photographer.subdomain}"
  end

  desc "Make a user a superadmin of every photographer: admins:grant_super[<facebook id or email>]"
  task :grant_super, [ :user ] => :environment do |_, args|
    user = find_user.call(args.fetch(:user))
    user.update!(god_mode: true)
    puts "#{user.name} (#{user.facebook_id}) is now a superadmin"
  end

  desc "List users who have signed in, most recent first, with the photographers they administer"
  task list: :environment do
    User.includes(photographer_admins: :photographer).order(updated_at: :desc).limit(50).each do |u|
      scopes = u.admin? ? "superadmin" : u.photographer_admins.map { |a| a.photographer.subdomain }.join(",")
      puts [ u.facebook_id, u.name, u.email_address, scopes.presence || "-" ].join("\t")
    end
  end
end
