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
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
