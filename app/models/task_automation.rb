# frozen_string_literal: true

# Sprint 23 — Automações declarativas para tarefas.
# Trigger events: "task.completed", "task.assigned", "task.idle_4h"
class TaskAutomation < ApplicationRecord
  TRIGGERS = %w[task.completed task.assigned task.idle_4h].freeze
  ACTIONS = %w[notify_assignees_of_dependents notify_assignee notify_supervisors llm_comment].freeze

  TRIGGER_LABELS = {
    "task.completed" => "Tarefa concluída",
    "task.assigned"  => "Tarefa atribuída",
    "task.idle_4h"   => "Tarefa parada há 4h (reservado)"
  }.freeze
  ACTION_LABELS = {
    "notify_assignees_of_dependents" => "Notificar responsáveis das tarefas dependentes",
    "notify_assignee"                => "Notificar o responsável",
    "notify_supervisors"             => "Notificar superiores da área",
    "llm_comment"                    => "🤖 IA comenta a tarefa (análise + próximo passo)"
  }.freeze

  belongs_to :demand, optional: true

  validates :name, presence: true
  validates :trigger_event, inclusion: { in: TRIGGERS }

  scope :enabled, -> { where(enabled: true) }
  scope :for_demand, ->(d) { where(demand_id: [ nil, d.id ]) }

  def action_kind
    action.is_a?(Hash) ? action["kind"].to_s : action.to_s
  end
end
