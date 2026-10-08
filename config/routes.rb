Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post "/graphql", to: "graphql#execute"

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  post "upload" => "upload#upload"

  # Admin sign-in. POST /auth/facebook is handled by OmniAuth middleware.
  get "auth/facebook/callback" => "sessions#create"
  get "auth/failure" => "sessions#failure"
  get "auth/me" => "sessions#show"
  delete "auth/session" => "sessions#destroy"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  get "upload" => "home#index"
  get "admin" => "home#index"
  get "admin/*path" => "home#index"
  get "upload/*path" => "home#index"
  root "home#index"
end
