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
  belongs_to :parent,   class_name: "ProjectTask", optional: true
  has_many   :subtasks, class_name: "ProjectTask", foreign_key: :parent_id, dependent: :destroy
  has_many   :time_entries,    class_name: "ProjectTaskTimeEntry",  dependent: :destroy
  has_many   :checklist_items, class_name: "ProjectTaskChecklistItem", dependent: :destroy
  has_many   :dependencies_as_successor,   class_name: "ProjectTaskDependency", foreign_key: :successor_id,   dependent: :destroy
  has_many   :dependencies_as_predecessor, class_name: "ProjectTaskDependency", foreign_key: :predecessor_id, dependent: :destroy
  has_many   :predecessors, through: :dependencies_as_successor,   source: :predecessor
  has_many   :successors,   through: :dependencies_as_predecessor, source: :successor
  has_many   :project_task_tags, dependent: :destroy
  has_many   :tags, through: :project_task_tags

  has_paper_trail

  validates :title,         presence: true, length: { maximum: 200 }
  validates :kanban_status, inclusion: { in: KANBAN_STATUSES }
  validates :priority,      inclusion: { in: PRIORITIES }
  validates :estimated_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :spent_hours,     numericality: { greater_than_or_equal_to: 0 }

  before_save :sync_timestamps_with_status
  before_save :touch_assigned_at, if: :assignee_id_changed?

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

  # ---- Sprint 17 — time tracking helpers ---------------------------------

  # Sessão aberta deste usuário para esta task (se houver)
  def running_entry_for(user)
    time_entries.running.find_by(user_id: user.id)
  end

  def timer_running_for?(user)
    return false unless user
    time_entries.running.where(user_id: user.id).exists?
  end

  # Active time = soma de todas sessões cronometradas (incluindo as abertas em tempo real)
  def active_seconds
    finished = time_entries.finished.sum(:duration_seconds).to_i
    open_now = time_entries.running.sum { |e| e.current_duration_seconds }
    finished + open_now
  end

  # Lead time = decorrido desde a atribuição até concluída (ou agora se em aberto)
  def lead_time_seconds
    return nil unless assigned_at
    finish = kanban_status == "concluida" ? (completed_at || Time.current) : Time.current
    [ (finish - assigned_at).to_i, 0 ].max
  end

  # Texto compacto pra exibir no card: "1h12 trab · 3d desde atribuição"
  def tracking_resumo
    parts = []
    if active_seconds > 0
      parts << "#{self.class.format_short(active_seconds)} trab"
    end
    if lt = lead_time_seconds
      parts << "#{self.class.format_short(lt)} desde atribuição"
    end
    parts.join(" · ").presence
  end

  # ---- Sprint 18 — bloqueios + progresso ---------------------------------

  # True se existe predecessor ainda nao concluido (bloqueia inicio).
  def blocked?
    return false if dependencies_as_successor.empty?
    predecessors.where.not(kanban_status: "concluida").exists?
  end

  def blocked_by
    predecessors.where.not(kanban_status: "concluida").to_a
  end

  # Progresso do checklist em %
  def checklist_progress
    total = checklist_items.size
    return nil if total.zero?
    done = checklist_items.count { |i| i.done }
    ((done.to_f / total) * 100).round
  end

  def self.format_short(secs)
    return "0s" if secs.to_i <= 0
    s = secs.to_i
    d = s / 86_400; s %= 86_400
    h = s / 3_600;  s %= 3_600
    m = s / 60
    return "#{d}d#{h > 0 ? h.to_s + 'h' : ''}" if d > 0
    return "#{h}h#{m > 0 ? m.to_s.rjust(2, '0') : ''}" if h > 0
    "#{m}min"
  end

  private

  def touch_assigned_at
    self.assigned_at = Time.current if assignee_id.present?
  end

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
