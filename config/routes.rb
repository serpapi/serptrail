Rails.application.routes.draw do
  root "sites#index"

  resources :sites do
    get :table, on: :member
    resources :keywords, except: [ :index ] do
      post :check, on: :member
      resources :checks, only: [ :index ]
      collection do
        get  :import
        post :import
      end
    end
  end

  get "/views", to: "views#index", as: :views

  resource :settings, controller: "tenants", only: [ :edit, :update ]

  get "up" => "rails/health#show", as: :rails_health_check
end
