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
      get   :triagem
      patch :triagem, action: :update_triagem
      patch :iniciar_n2
      get   :n2
      patch :n2, action: :update_n2
      patch :decidir_elegibilidade
    end

    resources :comments, only: %i[create]
    resources :attachments, only: %i[destroy]
  end

  get "dashboard", to: "dashboard#show", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
