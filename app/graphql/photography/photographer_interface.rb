module Photography
  module PhotographerInterface
    include GraphQL::Schema::Interface
    graphql_name "IPhotographer"
    field :id, ID, null: false
    field :name, String, null: false
    field :photos, PhotoType.connection_type, null: false, max_page_size: 50, default_page_size: 20
  end
end
