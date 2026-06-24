# frozen_string_literal: true

# Dependência entre tarefas: o predecessor precisa ser concluído antes do successor.
# kind: finish_to_start (default) — única implementada por enquanto.
class ProjectTaskDependency < ApplicationRecord
  KINDS = %w[finish_to_start start_to_start finish_to_finish].freeze

  belongs_to :predecessor, class_name: "ProjectTask"
  belongs_to :successor,   class_name: "ProjectTask"

  validates :kind, inclusion: { in: KINDS }
  validates :predecessor_id, uniqueness: { scope: :successor_id }
  validate  :not_self_referential
  validate  :no_cycle

  private

  def not_self_referential
    errors.add(:successor_id, "não pode depender de si mesmo") if predecessor_id == successor_id
  end

  # Impede ciclos: se successor já é ancestral (via dependency chain) do predecessor, rejeita.
  def no_cycle
    return if predecessor_id.blank? || successor_id.blank?
    visited = Set.new
    queue = [ successor_id ]
    while (node = queue.shift)
      next if visited.include?(node)
      visited << node
      return errors.add(:base, "dependência criaria ciclo") if node == predecessor_id
      next_ids = ProjectTaskDependency.where(predecessor_id: node).pluck(:successor_id)
      queue.concat(next_ids)
    end
  end
end
