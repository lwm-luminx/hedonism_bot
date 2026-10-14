namespace :storage do
  desc "Move every file on a storage service to the hot service: FROM=bucketeer"
  task move_to_hot: :environment do
    from = ENV.fetch("FROM")
    puts "Moving #{ActiveStorage::Blob.where(service_name: from).count} files from #{from} to #{StorageTier.hot_service_name}"
    moved = StorageTier.move_all(from: from)
    puts "Moved #{moved} files"
  end
end
