# frozen_string_literal: true

# Tarefa interna de um projeto PD&I (Demand).
# Tem dimensionamento de tempo (estimativa + horas gastas), prioridade, prazo,
# responsavel e status no kanban interno do projeto.
class ProjectTask < ApplicationRecord
  KANBAN_STATUSES = %w[backlog a_fazer em_andamento em_revisao concluida].freeze
  PRIORITIES      = %w[baixa media alta urgente].freeze

  belongs_to :demand
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :creator,  class_name: "User"

  has_many :versions, class_name: "PaperTrail::Version", as: :item, dependent: :destroy if defined?(PaperTrail)
  has_paper_trail if respond_to?(:has_paper_trail)

  validates :title,         presence: true, length: { maximum: 200 }
  validates :kanban_status, inclusion: { in: KANBAN_STATUSES }
  validates :priority,      inclusion: { in: PRIORITIES }
  validates :estimated_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :spent_hours,     numericality: { greater_than_or_equal_to: 0 }

  before_save :sync_timestamps_with_status

  scope :for_demand,    ->(d) { where(demand_id: d.id) }
  scope :open,          -> { where.not(kanban_status: "concluida") }
  scope :concluidas,    -> { where(kanban_status: "concluida") }
  scope :em_andamento,  -> { where(kanban_status: %w[em_andamento em_revisao]) }
  scope :by_kanban,     -> { order(:position, :id) }
  scope :atrasadas,     -> { where("due_date < ? AND kanban_status <> ?", Date.current, "concluida") }

  # Label human-friendly do status (usado nas views)
  def kanban_status_label
    {
      "backlog"      => "Backlog",
      "a_fazer"      => "A fazer",
      "em_andamento" => "Em andamento",
      "em_revisao"   => "Em revisão",
      "concluida"    => "Concluída"
    }[kanban_status] || kanban_status.to_s.humanize
  end

  def priority_label
    { "baixa" => "Baixa", "media" => "Média", "alta" => "Alta", "urgente" => "Urgente" }[priority] || priority.to_s.humanize
  end

  def atrasada?
    due_date.present? && kanban_status != "concluida" && due_date < Date.current
  end

  def horas_resumo
    return nil if estimated_hours.blank? && spent_hours.zero?
    est = estimated_hours.present? ? "#{estimated_hours}h estimadas" : nil
    spent = "#{spent_hours}h gastas"
    [est, spent].compact.join(" · ")
  end

  private

  def sync_timestamps_with_status
    if kanban_status_changed?
      case kanban_status
      when "em_andamento"
        self.started_at ||= Time.current
      when "concluida"
        self.completed_at ||= Time.current
        self.started_at  ||= completed_at
      end
    end
  end
end
