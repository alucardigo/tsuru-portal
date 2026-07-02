# frozen_string_literal: true

# Sprint 23 — Automações declarativas para tarefas.
# Trigger events: "task.completed", "task.assigned", "task.idle_4h"
class TaskAutomation < ApplicationRecord
  TASK_TRIGGERS = %w[task.completed task.assigned task.idle_4h].freeze
  DEMAND_TRIGGERS = %w[demand.elegivel demand.nao_elegivel demand.projeto demand.board_review demand.n2_completa].freeze
  TRIGGERS = (TASK_TRIGGERS + DEMAND_TRIGGERS).freeze

  ACTIONS = %w[notify_assignees_of_dependents notify_assignee notify_supervisors llm_comment webhook].freeze

  TRIGGER_LABELS = {
    "task.completed"      => "Tarefa concluída",
    "task.assigned"       => "Tarefa atribuída",
    "task.idle_4h"        => "Tarefa parada há 4h (reservado)",
    "demand.elegivel"     => "Projeto marcado Elegível",
    "demand.nao_elegivel" => "Projeto marcado Não elegível",
    "demand.projeto"      => "Sugestão promovida a Projeto de Fato",
    "demand.board_review" => "Projeto enviado à Diretoria",
    "demand.n2_completa"  => "Avaliação N2 concluída"
  }.freeze
  ACTION_LABELS = {
    "notify_assignees_of_dependents" => "Notificar responsáveis das tarefas dependentes",
    "notify_assignee"                => "Notificar o responsável",
    "notify_supervisors"             => "Notificar superiores da área",
    "llm_comment"                    => "🤖 IA comenta a tarefa (análise + próximo passo)",
    "webhook"                        => "🔗 Enviar para Power Automate (webhook HTTP)"
  }.freeze

  belongs_to :demand, optional: true

  validates :name, presence: true
  validates :trigger_event, inclusion: { in: TRIGGERS }
  validates :webhook_url, presence: true, if: -> { action_kind == "webhook" }

  scope :enabled, -> { where(enabled: true) }
  scope :for_demand, ->(d) { where(demand_id: [ nil, d.id ]) }

  def action_kind
    action.is_a?(Hash) ? action["kind"].to_s : action.to_s
  end

  def demand_scoped?
    trigger_event.to_s.start_with?("demand.")
  end
end
