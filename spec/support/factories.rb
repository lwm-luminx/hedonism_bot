RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot.lint(traits: true)
    FactoryBot.rewind_sequences
  end
end
