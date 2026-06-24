# frozen_string_literal: true

# /me/tasks — todas as tarefas atribuidas ao usuario atual, agrupadas por kanban_status.
module Me
  class TasksController < ApplicationController
    before_action :authenticate_user!

    def index
      base = ProjectTask.where(assignee_id: current_user.id)
                        .includes(:demand, :creator)
                        .order(:position, :id)
      @tasks_by_status = base.group_by(&:kanban_status)
      @statuses        = ProjectTask::KANBAN_STATUSES
      @metricas        = {
        total:           base.size,
        em_andamento:    base.count { |t| %w[em_andamento em_revisao].include?(t.kanban_status) },
        concluidas:      base.count { |t| t.kanban_status == "concluida" },
        atrasadas:       base.count { |t| t.atrasada? },
        horas_estimadas: base.sum { |t| t.estimated_hours.to_f },
        horas_gastas:    base.sum { |t| t.spent_hours.to_f },
        rodando_agora:   ProjectTaskTimeEntry.running.where(user_id: current_user.id).count
      }
    end
  end
end
