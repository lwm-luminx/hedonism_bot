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
  end
end
