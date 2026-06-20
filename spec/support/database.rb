RSpec.configure do |config|
  config.after(:each, type: :model) do |example|
    if example.exception
      # rubocop:disable RSpec/Output
      puts "\n--- DATABASE DUMP ON FAILURE ---"
      # Pretty print the records causing the issue
      ap described_class.all.as_json, indent: 2
    end
  end
end
