Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get 'dashboard', to: 'dashboard#show'
    resources :collections, only: [ :index, :show, :create, :update, :destroy ] do
      resources :items, only: [ :index, :create ] do
        get 'search', on: :collection
      end
    end
    get 'items/search', to: 'items#search'
    resources :items, only: [ :show, :update, :destroy ]
  end
end
