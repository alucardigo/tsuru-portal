# frozen_string_literal: true

# Painel de atualizações: um lugar único pra ver o que está acontecendo agora vs. o que
# está parado esperando alguém (standby), mais um feed cronológico de atividade recente
# (transições de estado + comentários + tarefas) — visão executiva, sem precisar entrar
# demanda por demanda.
class AtualizacoesController < ApplicationController
  before_action :require_gestor_or_above!

  # "Standby": a bola está na quadra de outra pessoa/área, não do time que está tocando o
  # projeto — aguardando autor responder, aguardando decisão da Diretoria ou parecer da FI.
  STANDBY_STATES = %w[awaiting_requester board_review em_avaliacao_fi].freeze

  # "Em andamento": alguém está de fato trabalhando ou a demanda está pronta pra próxima etapa.
  ACTIVE_STATES = %w[
    rascunho submetida aprovada_supervisor em_triagem n1_aprovada
    n2_em_andamento n2_completa elegivel in_execution projeto
  ].freeze

  TERMINAL_STATES = %w[concluida arquivada cancelada nao_elegivel n1_reprovada convertida].freeze

  ACTIVITY_LIMIT = 30

  def index
    @em_andamento = Demand.where(aasm_state: ACTIVE_STATES).order(updated_at: :desc)
    @em_standby   = Demand.where(aasm_state: STANDBY_STATES).order(updated_at: :desc)
    @concluidas_recentes = Demand.where(aasm_state: TERMINAL_STATES).order(updated_at: :desc).limit(8)
    @atividades = recent_activity_feed
  end

  private

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  # Mescla os três tipos de evento numa única linha do tempo, mais recente primeiro.
  def recent_activity_feed
    events = []

    DemandTransition.includes(:demand, :actor).order(created_at: :desc).limit(ACTIVITY_LIMIT).each do |t|
      events << {
        kind: :transition, at: t.created_at, demand: t.demand, actor: t.actor,
        detail: "#{UiHelper::STATUS_LABELS[t.to_state] || t.to_state.humanize}"
      }
    end

    Comment.includes(:demand, :user).order(created_at: :desc).limit(ACTIVITY_LIMIT).each do |c|
      events << {
        kind: :comment, at: c.created_at, demand: c.demand, actor: c.user,
        detail: c.body.to_s.truncate(90)
      }
    end

    ProjectTask.includes(:demand, :creator).order(updated_at: :desc).limit(ACTIVITY_LIMIT).each do |task|
      events << {
        kind: :task, at: task.updated_at, demand: task.demand, actor: task.creator,
        detail: "#{task.title} (#{UiHelper::STATUS_LABELS[task.kanban_status] || task.kanban_status.humanize})"
      }
    end

    events.sort_by { |e| -e[:at].to_i }.first(ACTIVITY_LIMIT)
  end
end
