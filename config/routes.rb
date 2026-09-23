Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ] do
    post :options
  end

  get "setup/:token", to: "setups#show", as: :setup
  post "setup/:token/options", to: "setups#options", as: :setup_options
  post "setup/:token", to: "setups#create"

  resources :passkeys, only: %i[ index create destroy ] do
    post :options, on: :collection
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :app_passwords, only: %i[ index create destroy ]

  scope "dav", module: "carddav", as: "carddav" do
    get "/", to: "root#show", as: :root
  end

  resources :contacts, only: %i[ index show new create ]

  root "contacts#index"
end
