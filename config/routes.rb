Rails.application.routes.draw do
  root "keywords#index"

  resources :keywords, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    post :check, on: :member
    resources :search_runs, only: [ :index, :show ]
  end

  resources :sites do
    get :table, on: :member
    resources :keywords, controller: "sites/keywords", except: [ :index ] do
      post :check, on: :member
      resources :checks, only: [ :index ]
      collection do
        get  :import
        post :import
      end
    end
  end

  resources :views, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]

  get "settings", to: "tenants#edit"
  resource :settings, controller: "tenants", only: [ :edit, :update ]
  resource :chat, controller: "chats", only: [ :show, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check
end
