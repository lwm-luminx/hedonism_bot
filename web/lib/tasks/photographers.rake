namespace :photographers do
  desc "Create a photographer (tenant): SUBDOMAIN=… NAME=…"
  task create: :environment do
    photographer = Photographer.create!(subdomain: ENV.fetch("SUBDOMAIN"), name: ENV.fetch("NAME"))
    puts "Photographer #{photographer.name} (#{photographer.subdomain})"
  end

  desc "Serve a photographer's site on a hostname: SUBDOMAIN=… HOST=gallery.example.com"
  task add_domain: :environment do
    photographer = Photographer.find_by!(subdomain: ENV.fetch("SUBDOMAIN"))
    domain = photographer.domains.create!(hostname: ENV.fetch("HOST"))
    puts "#{domain.hostname} → #{photographer.subdomain}"
  end

  desc "Stop serving a hostname: HOST=…"
  task remove_domain: :environment do
    PhotographerDomain.find_by!(hostname: ENV.fetch("HOST").downcase).destroy!
    puts "Removed"
  end

  desc "List photographers and their hostnames"
  task list: :environment do
    Photographer.includes(:domains).order(:subdomain).each do |p|
      puts [ p.subdomain, p.name, p.active ? "active" : "inactive", p.domains.map(&:hostname).join(", ") ].join("\t")
    end
  end
end
