# frozen_string_literal: true

# Iteração ágil dentro de um projeto (Demand).
class Sprint < ApplicationRecord
  STATES = %w[planejado ativo concluido].freeze

  belongs_to :demand
  has_many :project_tasks, dependent: :nullify

  validates :name, presence: true, length: { maximum: 80 }
  validates :state, inclusion: { in: STATES }
  validate  :end_after_start

  scope :ordered, -> { order(start_date: :desc, created_at: :desc) }
  scope :active,  -> { where(state: "ativo") }

  def velocity_points
    project_tasks.where(kanban_status: "concluida").sum(:story_points).to_i
  end

  def total_points
    project_tasks.sum(:story_points).to_i
  end

  def in_progress?
    state == "ativo"
  end

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "deve ser depois do início") if end_date < start_date
  end
end
