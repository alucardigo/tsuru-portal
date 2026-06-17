module UiHelper
  STATUS_LABELS = {
    "rascunho"           => "Rascunho",
    "submetida"          => "Submetida",
    "em_triagem"         => "Em triagem",
    "n1_aprovada"        => "N1 aprovada",
    "n1_reprovada"       => "N1 reprovada",
    "n2_em_andamento"    => "N2 em andamento",
    "n2_completa"        => "N2 completa",
    "awaiting_requester" => "Aguardando autor",
    "board_review"       => "Em revisão diretoria",
    "em_avaliacao_fi"    => "Em avaliação FI",
    "elegivel"           => "Elegível Lei do Bem",
    "nao_elegivel"       => "Não elegível",
    "aprovada_supervisor" => "Aprovada pelo supervisor",
    "projeto"            => "Projeto INOVA BEL",
    "in_execution"       => "PD&I em execução",
    "concluida"          => "Concluída",
    "arquivada"          => "Arquivada",
    "cancelada"          => "Cancelada"
  }.freeze

  # FlowTrack: 6 macro-etapas do fluxo INOVA BEL (maps aasm_state -> 0..5)
  FLOW_STEPS = [ "Sugestão", "Supervisor", "Análise", "Diretoria", "FI", "Projeto" ].freeze

  def status_pill(state, klass: "")
    label = STATUS_LABELS[state.to_s] || state.to_s.humanize
    content_tag(:span, label, class: "status-pill status-#{state} #{klass}")
  end

  def flow_step_for(state)
    case state.to_s
    when "rascunho", "awaiting_requester" then 0
    when "submetida" then 1
    when "aprovada_supervisor", "em_triagem", "n1_aprovada", "n1_reprovada",
         "n2_em_andamento", "n2_completa" then 2
    when "board_review" then 3
    when "em_avaliacao_fi" then 4
    when "elegivel", "projeto", "in_execution", "concluida" then 5
    else -1
    end
  end

  def flow_track(state)
    step = flow_step_for(state)
    blocked = %w[n1_reprovada nao_elegivel cancelada arquivada].include?(state.to_s)
    content_tag(:div, class: "flow-track") do
      FLOW_STEPS.each_with_index.map do |label, i|
        bar_cls = if blocked && i == step
                    "flow-bar flow-bar-blocked"
        elsif i <= step
                    "flow-bar flow-bar-done"
        else
                    "flow-bar"
        end
        seg = content_tag(:div, "", class: bar_cls)
        lbl = content_tag(:div, label, class: i == step ? "flow-label-cur" : "flow-label")
        concat content_tag(:div, [ seg, lbl ].join.html_safe, class: "flow-seg")
      end.join.html_safe
    end
  end

  def pill(text, color: "gray", klass: "")
    content_tag(:span, text, class: "pill pill-#{color} #{klass}")
  end

  def initials_of(name_or_user)
    str = name_or_user.respond_to?(:display_name) ? name_or_user.display_name : name_or_user.to_s
    parts = str.to_s.split(/\s+/)
    (parts.first(2).map { |p| p[0] }.join).upcase[0, 2]
  end

  def avatar(user, size: 24, color: "bg-gray-200 text-gray-700")
    return "" unless user
    content_tag(:span, initials_of(user),
                class: "inline-flex items-center justify-center rounded-full text-[10px] font-semibold #{color}",
                style: "width:#{size}px;height:#{size}px;")
  end

  def role_label(role)
    {
      "colaborador"  => "Colaborador",
      "gestor"       => "Superior da área",
      "analista_pdi" => "Analista T&I",
      "admin"        => "Administrador",
      "board"        => "Diretoria",
      "fi"           => "FI Group"
    }[role.to_s] || role.to_s.humanize
  end

  # Navigation per role for the sidebar
  def sidebar_nav_for(user)
    return [] unless user

    case user.role
    when "colaborador"
      [
        { key: "inicio",     label: "Início",            icon: :home,    path: dashboard_path },
        { key: "demandas",   label: "Minhas demandas",   icon: :bulb,    path: demands_path },
        { key: "nova",       label: "Nova demanda",      icon: :plus,    path: new_demand_path },
        { key: "biblioteca", label: "Biblioteca PD&I",   icon: :book,    path: "#" }
      ]
    when "gestor"
      [
        { key: "aprovar",    label: "Para aprovar",      icon: :inbox,   path: gestor_demands_path, badge: gestor_pending_count },
        { key: "minha-area", label: "Minha área",        icon: :folder,  path: demands_path },
        { key: "historico",  label: "Histórico",         icon: :doc,     path: demands_path },
        { key: "biblioteca", label: "Biblioteca PD&I",   icon: :book,    path: "#" }
      ]
    when "analista_pdi"
      [
        { key: "esteira",      label: "Esteira do comitê", icon: :triage,  path: dashboard_path, badge: pending_count(user) },
        { key: "pipeline",     label: "Pipeline Kanban",   icon: :chart,   path: pipeline_path },
        { key: "projetos",     label: "Projetos PD&I",     icon: :folder,  path: demands_path },
        { key: "elegibilidade", label: "Elegibilidade",     icon: :shield,  path: demands_path },
        { key: "defesa",       label: "Composição defesa", icon: :doc,     path: "#" },
        { key: "evidencias",   label: "Evidências",        icon: :file,    path: "#" },
        { key: "biblioteca",   label: "Biblioteca PD&I",   icon: :book,    path: "#" }
      ]
    when "admin"
      [
        { key: "esteira",     label: "Esteira do comitê", icon: :triage,  path: admin_demands_path },
        { key: "pipeline",    label: "Pipeline Kanban",   icon: :chart,   path: pipeline_path },
        { key: "metricas",    label: "Métricas",          icon: :chart,   path: admin_metrics_path },
        { key: "usuarios",    label: "Usuários",          icon: :user,    path: admin_users_path },
        { key: "elegibilidade", label: "Elegibilidade",   icon: :shield,  path: admin_demands_path },
        { key: "exportar",    label: "Exportar",          icon: :download, path: admin_demands_path }
      ]
    when "board"
      [
        { key: "resumo",     label: "Resumo executivo",  icon: :chart,   path: dashboard_path },
        { key: "portfolio",  label: "Portfólio",         icon: :folder,  path: demands_path },
        { key: "decisoes",   label: "Decisões pendentes", icon: :flag,    path: board_demands_path, badge: board_pending_count },
        { key: "exportar",   label: "Exportar",          icon: :download, path: "#" }
      ]
    when "fi"
      [
        { key: "fila-fi",    label: "Fila de avaliação", icon: :triage,  path: fi_demands_path, badge: fi_pending_count },
        { key: "projetos",   label: "Projetos avaliados", icon: :folder, path: demands_path },
        { key: "biblioteca", label: "Biblioteca PD&I",   icon: :book,    path: "#" }
      ]
    else
      []
    end
  end

  def pending_count(user)
    return nil unless user.gestor_or_above?

    Demand.where(aasm_state: %w[submetida em_triagem n2_em_andamento board_review]).count
  rescue StandardError
    nil
  end

  def board_pending_count
    Demand.where(aasm_state: "board_review").count
  rescue StandardError
    nil
  end

  def gestor_pending_count
    scope = Demand.where(aasm_state: "submetida")
    scope = scope.where(area_impactada: current_user.area) if current_user&.gestor?
    scope.count
  rescue StandardError
    nil
  end

  def fi_pending_count
    Demand.where(aasm_state: "em_avaliacao_fi").count
  rescue StandardError
    nil
  end
end
