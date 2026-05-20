Rails.application.routes.draw do
  root "sites#index"

  resources :keywords, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    post :check, on: :member
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

  resource :settings, controller: "tenants", only: [ :edit, :update ]

  get "up" => "rails/health#show", as: :rails_health_check
end
