require 'rails_helper'

RSpec.describe "Legal pages", type: :request do
  %w[/privacy /data-deletion].each do |path|
    it "credits Love Wins Media on #{path}" do
      get path
      expect(response.body.scan('href="https://lovewinsmedia.com" target="_blank" rel="noopener"').size).to eq(2)
    end
  end
end
