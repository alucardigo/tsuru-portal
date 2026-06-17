class PipelineController < ApplicationController
  before_action :require_gestor_or_above!
  before_action :set_demand, only: :mover

  # Colunas alinhadas às 6 macro-etapas do fluxo INOVA BEL (+ Entrada e Bloqueadas).
  # drop: true => aceita cards arrastados (dispara transição). drop: false => só visual.
  COLUMNS = [
    { key: 1, label: "Entrada",          drop: false, states: %w[rascunho submetida awaiting_requester] },
    { key: 2, label: "Aprovada Supervisor", drop: true, states: %w[aprovada_supervisor] },
    { key: 3, label: "Análise Interna",  drop: true,  states: %w[em_triagem n1_aprovada n2_em_andamento n2_completa] },
    { key: 4, label: "Diretoria",        drop: true,  states: %w[board_review] },
    { key: 5, label: "FI Group",         drop: true,  states: %w[em_avaliacao_fi] },
    { key: 6, label: "Projeto de Fato",  drop: true,  states: %w[elegivel projeto in_execution concluida] },
    { key: 0, label: "Bloqueadas",       drop: false, states: %w[n1_reprovada nao_elegivel cancelada arquivada] }
  ].freeze

  def show
    @columns = COLUMNS.map do |col|
      demands = Demand.where(aasm_state: col[:states])
                      .includes(:user)
                      .order(updated_at: :desc)
                      .limit(25)
      col.merge(demands: demands, total: Demand.where(aasm_state: col[:states]).count)
    end
  end

  # Arraste de card entre colunas -> dispara a transição válida da etapa de destino.
  def mover
    target = params[:etapa].to_i
    event, motivo = evento_para(@demand, target)

    unless event
      render json: { ok: false, message: motivo || "Movimento não permitido a partir de #{@demand.etapa_label}." },
             status: :unprocessable_content
      return
    end

    if @demand.public_send(event) && @demand.save
      render json: { ok: true, codigo: @demand.codigo_display, novo_estado: @demand.aasm_state }
    else
      render json: { ok: false, message: motivo_guard(event, @demand) }, status: :unprocessable_content
    end
  rescue StandardError => e
    render json: { ok: false, message: "Erro: #{e.message}" }, status: :unprocessable_content
  end

  private

  # Mapeia (estado atual, etapa destino) -> evento do state machine.
  # Retorna [evento, nil] ou [nil, mensagem_de_recusa].
  def evento_para(demand, target)
    s = demand.aasm_state
    case target
    when 2 # Aprovada Supervisor
      return [:aprovar_supervisor, nil] if s == "submetida"
      [nil, "Só sugestões aguardando o supervisor podem ser aprovadas aqui."]
    when 3 # Análise Interna (inicia triagem)
      return [:iniciar_triagem, nil] if s == "aprovada_supervisor"
      [nil, "A triagem só inicia após a aprovação do supervisor."]
    when 4 # Diretoria
      return [:enviar_para_board, nil] if s == "n2_completa"
      [nil, "Conclua a Avaliação N2 e registre o parecer técnico antes de enviar à diretoria."]
    when 5 # FI Group
      return [:aprovar_diretoria, nil] if s == "board_review"
      [nil, "Só a diretoria pode encaminhar à FI (estado precisa ser 'Em revisão diretoria')."]
    when 6 # Projeto de Fato
      return [:fi_aprovar, nil] if s == "em_avaliacao_fi"
      return [:tornar_projeto, nil] if s == "elegivel"
      [nil, "Só projetos com parecer FI positivo viram Projeto de Fato."]
    else
      [nil, "Esta coluna não aceita arraste (mova pelas etapas do fluxo)."]
    end
  end

  def motivo_guard(event, demand)
    case event
    when :enviar_para_board, :marcar_elegivel
      "Registre o parecer técnico antes desta etapa."
    else
      "Transição '#{event}' não pôde ser aplicada ao estado atual (#{demand.etapa_label})."
    end
  end

  def set_demand
    @demand = Demand.find(params[:id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end
end
