Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "dashboard#index"

  # Authentication
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Spreadsheets
  resources :spreadsheets do
    # Sync action for spreadsheet
    resource :sync, only: [ :create ], controller: "spreadsheets/syncs"

    # Sheets (nested under spreadsheets)
    resources :sheets, only: [ :show, :update ] do
      # Nested controllers for specific sheet actions
      resource :sync, only: [ :create ], controller: "sheets/syncs"
      resource :append, only: [ :create ], controller: "sheets/appends"
      resource :clear, only: [ :destroy ], controller: "sheets/clears"
    end
  end

  # User Permissions (Admin only)
  resources :user_permissions, only: [ :index, :edit, :update ]
end
