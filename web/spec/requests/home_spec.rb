require 'rails_helper'

RSpec.describe "Homes", type: :request do
  before do
    mock_photographer
  end

  describe "GET /index" do
    it 'renders the react component' do
      get '/', headers: { "Host": 'test.lumiere.host' }
      expect(response).to render_template('home/index')
    end

    it 'credits Love Wins Media above the app and in the footer', :aggregate_failures do
      get '/', headers: { "Host": 'test.lumiere.host' }
      expect(response.body.scan('href="https://lovewinsmedia.com" target="_blank" rel="noopener"').size).to eq(2)
      expect(response.body).to include("© #{Time.current.year} Love Wins Media, Inc.")
    end

    it 'leaves Google Analytics out without a measurement ID' do
      get '/', headers: { "Host": 'test.lumiere.host' }
      expect(response.body).not_to include('googletagmanager')
    end

    context 'with a measurement ID' do
      around do |example|
        Rails.configuration.x.google_analytics_id = 'G-LUMIERE'
        example.run
      ensure
        Rails.configuration.x.google_analytics_id = nil
      end

      it 'loads Google Analytics', :aggregate_failures do
        get '/', headers: { "Host": 'test.lumiere.host' }
        expect(response.body).to include('https://www.googletagmanager.com/gtag/js?id=G-LUMIERE')
        expect(response.body).to include(%(gtag('config', "G-LUMIERE")))
      end
    end
  end
end
