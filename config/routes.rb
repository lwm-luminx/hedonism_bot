Rails.application.routes.draw do
  post "callbacks/facebook/data-deletion", to: "facebook_data_deletions#create"
  get "privacy/deletion/:confirmation_code", to: "facebook_data_deletions#show", as: :facebook_deletion_status
  # Rails serves these static views, including the existing .html URLs.
  get "privacy", to: "legal#privacy", as: :privacy, defaults: { format: :html }
  get "data-deletion", to: "legal#data_deletion", as: :data_deletion, defaults: { format: :html }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post "/graphql", to: "graphql#execute"

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  # Errors from the frontend, logged for heroku logs.
  post "client_errors" => "client_errors#create"

  get "auth/native", to: "native_accounts#new"
  get "auth/native/complete", to: "native_accounts#complete"
  post "auth/native/exchange", to: "native_accounts#exchange"
  delete "auth/native/session", to: "native_accounts#destroy"

  post "auth/start", to: "auth_bridges#start"
  get "auth/bridge", to: "auth_bridges#new"
  get "auth/return", to: "auth_bridges#complete"

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
