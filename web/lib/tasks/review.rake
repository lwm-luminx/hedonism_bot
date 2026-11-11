namespace :review do
  desc "Create the App Review demo photographer and print a reusable review device code to set"
  task setup: :environment do
    photographer = Photographer.find_or_create_by!(subdomain: ReviewAccess.subdomain) do |p|
      p.name = ENV.fetch("NAME", "Lumière Review Demo")
    end
    puts "Review photographer: #{photographer.name} (#{photographer.subdomain})"
    if ReviewAccess.code
      puts "REVIEW_DEVICE_CODE is already set."
    else
      code = SecureRandom.hex(10).upcase.scan(/.{4}/).join("-")
      puts "Set this config var, then give the code to App Review in App Store Connect's review notes:"
      puts "  REVIEW_DEVICE_CODE=#{code}"
    end
  end
end
