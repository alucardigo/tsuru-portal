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
      patch  :arquivar
      delete :hard_destroy
      get   :versions
      get   :converter
      post  :converter, action: :realizar_conversao
      patch :vincular_sankhya
    end

    resources :comments, only: %i[create]
    resources :attachments, only: %i[destroy]

    # Sprint 14 — tarefas + kanban interno + documentos
    resources :tasks, controller: "project_tasks", except: [:show] do
      member do
        patch :move
        post  :reassign
        post "timer/start", to: "project_task_timers#start", as: :start_timer
        post "timer/stop",  to: "project_task_timers#stop",  as: :stop_timer
      end
      collection do
        get :kanban
        get :calendar, to: "project_task_calendars#show"
        post :bulk, to: "project_task_bulks#create"
      end
      resources :checklist_items, controller: "project_task_checklist_items", only: %i[create destroy] do
        member { patch :toggle }
      end
      resources :dependencies, controller: "project_task_dependencies", only: %i[create destroy]
      resources :comments, controller: "project_task_comments", only: %i[create destroy] do
        post "reactions/toggle", to: "project_task_reactions#toggle", as: :toggle_reaction, on: :member
      end
      resources :attachments, controller: "project_task_attachments", only: %i[destroy]
      resource  :watcher,  controller: "project_task_watchers", only: %i[create destroy]
    end

    resources :sprints do
      member do
        post :assign_task
        post :unassign_task
      end
    end

    resources :defense_dossiers, controller: "demand_defense_dossiers" do
      member { get :pdf }
      resources :defense_evidences, controller: "demand_defense_evidences", only: %i[create destroy]
    end
    resources :task_field_definitions, controller: "demand_task_field_definitions", only: %i[index create destroy]
    resources :task_templates, controller: "project_task_templates", only: %i[index create destroy] do
      member { post :apply }
    end
    resource :task_workflow, controller: "demand_task_workflows", only: %i[show update destroy]
    resources :documentos, only: %i[index create destroy], controller: "demand_documentos"

    resource :lei_do_bem_record, only: %i[show new create edit update], path: "lei-do-bem" do
      resources :expenses, only: %i[new create edit update destroy]
      resources :team_members, only: %i[new create edit update destroy], path: "equipe"
      resources :partnerships, only: %i[new create edit update destroy], path: "parcerias"
    end
  end

  namespace :me do
    resources :tasks, only: %i[index]
    resource  :timesheet, only: %i[show]
  end

  get "gantt", to: "gantt#show", as: :gantt
  get "search/quick", to: "search#quick", as: :quick_search
  scope path: "roadmap", controller: "roadmap" do
    get "automations", action: :automations, as: :roadmap_automations
  end

  # Bloco D — Portfólio Lei do Bem (N1/N2/N3)
  get "elegibilidade", to: "pdi/eligibility#index", as: :pdi_elegibilidade
  get "defesa",        to: "pdi/defenses#index",    as: :pdi_defesa
  get "evidencias",    to: "pdi/evidences#index",   as: :pdi_evidencias

  # Painel de atualizações — em andamento vs. standby + feed de atividade recente
  get "atualizacoes", to: "atualizacoes#index", as: :atualizacoes

  # Bloco F — Biblioteca PD&I
  get  "biblioteca",     to: "knowledge_articles#index", as: :biblioteca
  get  "biblioteca/:id", to: "knowledge_articles#show",  as: :biblioteca_article

  # Bloco E — Central de exportação (acessível além de admin)
  get "exportar",             to: "exports#index",     as: :exports
  get "exportar/demandas",    to: "exports#demandas",  as: :exports_demandas
  get "exportar/tarefas",     to: "exports#tarefas",   as: :exports_tarefas
  get "exportar/timesheet",   to: "exports#timesheet", as: :exports_timesheet

  # Bloco G — Relatórios de IA sob demanda
  post "demands/:demand_id/ai_report", to: "ai_reports#create_for_demand", as: :ai_report_for_demand
  post "dashboard/ai_report",          to: "ai_reports#create_portfolio",  as: :ai_report_portfolio

  # Bloco H — token de API pessoal (Power Automate / integrações)
  post "api_token/regenerate", to: "api_tokens#regenerate", as: :regenerate_api_token

  namespace :api do
    namespace :v1 do
      resources :tasks, only: %i[create] do
        post "comments", to: "tasks#create_comment", on: :member
      end

      # API administrativa completa — pensada para agentes de codigo (MCP) gerenciarem
      # o Tsuru remotamente com privilegios de admin. Ver Api::V1::Admin::BaseController.
      namespace :admin do
        resources :users, only: %i[index show create update destroy]

        resources :demands, only: %i[index show create update] do
          post "transition", on: :member
          post "comments",   to: "demands#create_comment", on: :member
        end

        resources :project_tasks, only: %i[index show create update]

        resources :areas, only: %i[index create update destroy]

        get "organograma", to: "organograma#index"

        post "reports/demand/:demand_id", to: "reports#create_for_demand", as: :report_for_demand
        post "reports/portfolio",         to: "reports#create_portfolio"

        # Ingestão de token FI Group pelo agente-guardião (headless) — mantém a
        # integração viva renovando o Bearer sem intervenção humana.
        post "figroup/refresh_token", to: "figroup#refresh_token"
        get  "figroup/status",        to: "figroup#status"
      end
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
        get   :excluir
        post  :excluir, action: :realizar_exclusao
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
    resources :tags, only: %i[index create update destroy]
    resources :areas, only: %i[index create destroy] do
      member do
        patch :assign_user
        patch :remove_user
      end
    end
    resources :llm_providers, only: %i[index create update destroy] do
      member { post :test }
    end
    resources :automations, only: %i[index create update destroy]
    resources :knowledge_articles, only: %i[index create update destroy]
    resources :sankhya_mappings, only: %i[index create update destroy] do
      member { post :sync }
    end
    get "auditoria", to: "audits#index", as: :auditoria
    get "organograma", to: "organograma#index", as: :organograma

    # Integração FI Group (portal LeidoBem) — pull/push de projetos Lei do Bem
    get  "figroup",          to: "figroup#index",        as: :figroup
    post "figroup/token",    to: "figroup#create_token", as: :figroup_token
    post "figroup/pull",     to: "figroup#pull",         as: :figroup_pull
    post "figroup/push_all", to: "figroup#push_all",     as: :figroup_push_all
    post "figroup/push/:id", to: "figroup#push",         as: :figroup_push
    post "figroup/sync_now",         to: "figroup#sync_now",         as: :figroup_sync_now
    post "figroup/toggle_auto_sync", to: "figroup#toggle_auto_sync", as: :figroup_toggle_auto_sync
  end

  resources :notifications, only: %i[index] do
    member { patch :mark_read }
    collection { post :mark_all_read }
  end

  get "dashboard", to: "dashboard#show", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
