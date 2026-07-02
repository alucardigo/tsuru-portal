# frozen_string_literal: true

# /me/tasks — todas as tarefas atribuidas ao usuario atual, agrupadas por kanban_status.
module Me
  class TasksController < ApplicationController
    before_action :authenticate_user!

    def index
      full = ProjectTask.where(assignee_id: current_user.id).includes(:demand, :creator)
      @metricas = {
        total:           full.size,
        em_andamento:    full.count { |t| %w[em_andamento em_revisao].include?(t.kanban_status) },
        concluidas:      full.count { |t| t.kanban_status == "concluida" },
        atrasadas:       full.count(&:atrasada?),
        horas_estimadas: full.sum { |t| t.estimated_hours.to_f },
        horas_gastas:    full.sum { |t| t.spent_hours.to_f },
        rodando_agora:   ProjectTaskTimeEntry.running.where(user_id: current_user.id).count
      }

      base = full
      if params[:q].present?
        like = "%#{ProjectTask.sanitize_sql_like(params[:q])}%"
        base = base.select { |t| t.title.to_s.match?(/#{Regexp.escape(params[:q])}/i) || t.demand.title.to_s.match?(/#{Regexp.escape(params[:q])}/i) }
      end
      base = base.select { |t| t.kanban_status == params[:status] } if params[:status].present?
      base = base.select { |t| t.priority == params[:priority] } if params[:priority].present?
      base = base.select { |t| t.demand_id == params[:demand_id].to_i } if params[:demand_id].present?
      base = base.select(&:atrasada?) if params[:atrasadas] == "1"

      @tasks_by_status = base.sort_by { |t| [ t.position.to_i, t.id ] }.group_by(&:kanban_status)
      @statuses        = ProjectTask::KANBAN_STATUSES
      @demandas_opcoes = full.map(&:demand).uniq.sort_by(&:codigo_display)
    end
  end
end
