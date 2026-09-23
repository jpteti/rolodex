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

  # CardDAV. Clients find the service from /.well-known/carddav (RFC 6764) or by probing "/".
  dav_verbs = %i[ options propfind proppatch report get put delete mkcol ]
  match "/.well-known/carddav", to: redirect("/dav/", status: 301), via: :all
  match "/", to: "carddav/dav#serve", via: %i[ options propfind ]
  match "/dav", to: "carddav/dav#serve", via: dav_verbs, as: :carddav_root
  match "/dav/*path", to: "carddav/dav#serve", via: dav_verbs, format: false

  resources :contacts, only: %i[ index show new create ] do
    resource :archive, only: %i[ create destroy ]
  end
  get "archive", to: "archives#index", as: :archived_contacts

  root "contacts#index"
end
