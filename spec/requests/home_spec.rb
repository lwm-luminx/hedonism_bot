require 'rails_helper'

RSpec.describe "Homes", type: :request do
  before do
    mock_tenant
  end

  describe "GET /index" do
    it 'renders the react component' do
      get '/', headers: { "Host": 'test.hedonism.local' }
      expect(response).to render_template('home/index')
    end
  end
end
