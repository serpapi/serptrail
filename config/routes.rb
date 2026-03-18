Rails.application.routes.draw do
  root "sites#index"

  resources :sites do
    resources :keywords, except: [ :index, :show ] do
      post :check, on: :member
    end
  end

  resources :keywords, only: [] do
    resources :checks, only: [ :index ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
