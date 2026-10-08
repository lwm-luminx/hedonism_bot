namespace :service_accounts do
  desc "Issue a single-use, ten-minute device sign-in code: ID=service_account_id"
  task device_code: :environment do
    account = ServiceAccount.active.find(ENV.fetch("ID"))
    grant, code = DeviceLoginGrant.issue!(service_account: account)
    puts "Device code (shown once): #{code}"
    puts "Expires at #{grant.expires_at.iso8601}"
  end

  desc "Create a service account token for a photographer: SUBDOMAIN=… NAME=…"
  task create: :environment do
    photographer = Photographer.find_by!(subdomain: ENV.fetch("SUBDOMAIN"))
    account, token = ServiceAccount.issue!(photographer: photographer, name: ENV.fetch("NAME", "Uploader"))
    puts "Service account #{account.name} (#{account.id}) for #{photographer.subdomain}"
    puts "Token (shown once): #{token}"
  end

  desc "List service accounts"
  task list: :environment do
    ServiceAccount.includes(:photographer).order(:created_at).each do |a|
      state = a.revoked_at ? "revoked" : "active"
      puts [ a.id, a.photographer.subdomain, a.name, state, a.last_used_at || "never used" ].join("\t")
    end
  end

  desc "Revoke a service account: ID=…"
  task revoke: :environment do
    ServiceAccount.find(ENV.fetch("ID")).revoke!
    puts "Revoked"
  end
end
