require 'rails_helper'

RSpec.describe "Tenancy", type: :request do
  let!(:luminx) { create(:photographer, subdomain: "luminx", name: "Luminx") }
  let!(:sam) { create(:photographer, subdomain: "sam", name: "Sam") }

  let(:photographer_query) { { query: "{ photographer { subdomain } }" } }

  before { create(:photographer_domain, photographer: luminx, hostname: "gallery.luminx.media") }

  def subdomain_for(host)
    post "/graphql", params: photographer_query, headers: { "Host" => host }
    JSON.parse(response.body).dig("data", "photographer", "subdomain")
  end

  it "serves the photographer registered for a custom domain" do
    expect(subdomain_for("gallery.luminx.media")).to eq("luminx")
  end

  it "serves the photographer named by the subdomain" do
    expect(subdomain_for("sam.lumiere.host")).to eq("sam")
  end

  it "returns 404 for a host no photographer serves" do
    post "/graphql", params: photographer_query, headers: { "Host" => "unknown.herokuapp.com" }
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for the site on an unknown host" do
    get "/", headers: { "Host" => "unknown.herokuapp.com" }
    expect(response).to have_http_status(:not_found)
  end

  it "serves Luminx on its service subdomain" do
    expect(subdomain_for("luminx.lumiere.host")).to eq("luminx")
  end

  it "does not infer a photographer on an unrelated or nested hostname" do
    %w[luminx.example.com luminx.other.lumiere.host].each do |host|
      get "/", headers: { "Host" => host }
      expect(response).to have_http_status(:not_found)
    end
  end

  it "requires a photographer token on the shared API" do
    post "/graphql", params: photographer_query, headers: { "Host" => "api.lumiere.host" }
    expect(response).to have_http_status(:not_found)
  end

  describe "IDs from another photographer" do
    let(:other_album) { create(:album, photographer: sam) }

    it "resolves nothing through node" do
      post "/graphql", params: { query: "query($id: ID!) { node(id: $id) { id } }", variables: { id: other_album.to_gid_param }.to_json },
                       headers: { "Host" => "gallery.luminx.media" }
      expect(JSON.parse(response.body).dig("data", "node")).to be_nil
    end

    it "resolves the photographer's own upload batch through node", :aggregate_failures do
      promise = create(:photo_promise, photographer: luminx)
      post "/graphql", params: { query: "query($id: ID!) { node(id: $id) { __typename id } }", variables: { id: promise.to_gid_param }.to_json },
                       headers: { "Host" => "gallery.luminx.media" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "node")).to eq("__typename" => "PhotoPromise", "id" => promise.to_gid_param)
    end

    it "resolves the photographer's own records" do
      own = create(:album, photographer: luminx)
      expect(HedonismBotSchema.object_from_id(own.to_gid_param, { photographer: luminx })).to eq(own)
    end

    it "does not resolve another photographer's records" do
      expect(HedonismBotSchema.object_from_id(other_album.to_gid_param, { photographer: luminx })).to be_nil
    end
  end
end
