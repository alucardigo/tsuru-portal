Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords"
  }

  resources :demands do
    member do
      patch :submeter
      patch :iniciar_triagem
      get :triagem
      patch :triagem, action: :update_triagem
    end

    resources :comments, only: %i[create]
  end

  get "dashboard", to: "dashboard#show", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
