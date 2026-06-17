Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords"
  }

  devise_scope :user do
    resource :two_factor_setup,
             only: %i[new create destroy],
             controller: "users/two_factor_setup",
             as: "users_two_factor_setup" do
      get :backup, on: :member
    end
  end

  resources :demands do
    member do
      patch :submeter
      patch :retomar
      patch :iniciar_triagem
      get   :triagem
      patch :triagem, action: :update_triagem
      patch :iniciar_n2
      get   :n2
      patch :n2, action: :update_n2
      patch :decidir_elegibilidade
      patch :tornar_projeto
      get   :versions
    end

    resources :comments, only: %i[create]
    resources :attachments, only: %i[destroy]

    # Sprint 14 — tarefas + kanban interno + documentos
    resources :tasks, controller: "project_tasks", except: [:show] do
      member { patch :move }
      collection { get :kanban }
    end
    resources :documentos, only: %i[index create destroy], controller: "demand_documentos"

    resource :lei_do_bem_record, only: %i[show new create edit update], path: "lei-do-bem" do
      resources :expenses, only: %i[new create edit update destroy]
      resources :team_members, only: %i[new create edit update destroy], path: "equipe"
      resources :partnerships, only: %i[new create edit update destroy], path: "parcerias"
    end
  end

  namespace :board do
    resources :demands, only: %i[index show] do
      member do
        post :approve
        post :reject
        post :defer
        post :encaminhar_fi
      end
    end
  end

  namespace :gestor do
    resources :demands, only: %i[index show] do
      member do
        post :encaminhar
        post :devolver
        post :arquivar
      end
    end
  end

  namespace :fi do
    resources :demands, only: %i[index show] do
      member do
        post :aprovar
        post :reprovar
      end
    end
  end

  post "validators/linus", to: "validators#linus", as: :linus_validator

  get "pipeline", to: "pipeline#show", as: :pipeline
  post "pipeline/:id/mover", to: "pipeline#mover", as: :pipeline_mover

  namespace :admin do
    resources :users, only: %i[index new create update] do
      member do
        patch :toggle_active
        patch :vincular_superior
      end
    end
    resources :demands, only: %i[index] do
      member do
        get :formpd
        get :sankhya
        get :relatorio_n3
      end
    end
    get "metrics", to: "metrics#show", as: :metrics
    get "auditoria", to: "audits#index", as: :auditoria
    get "organograma", to: "organograma#index", as: :organograma
  end

  resources :notifications, only: %i[index] do
    member { patch :mark_read }
    collection { post :mark_all_read }
  end

  get "dashboard", to: "dashboard#show", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
