# frozen_string_literal: true

# Sprint 19 — Gantt / Timeline view.
# /gantt          → todas as demandas com tarefas (visão portfolio)
# /gantt?demand=N → uma demanda específica (visão de projeto)
class GanttController < ApplicationController
  before_action :authenticate_user!

  def show
    @demand = Demand.find_by(id: params[:demand]) if params[:demand].present?
    if @demand
      begin
        authorize(@demand, :show?)
      rescue Pundit::NotAuthorizedError
        redirect_to demands_path, alert: "Sem permissão para ver este projeto." and return
      end
    end
    base = if @demand
             @demand.tasks
           else
             # Portfolio: admin/analista/board veem tudo; outros vêem só projetos próprios.
             scope = ProjectTask.joins(:demand).where.not(demands: { aasm_state: %w[arquivada cancelada] })
             if current_user.admin? || current_user.analista_pdi? || current_user.board?
               scope
             else
               scope.where(demands: { user_id: current_user.id })
             end
           end

    tasks = base.includes(:assignee, :demand).order(:position, :id).to_a

    # Janela temporal: padrão = min(started_at, assigned_at, created_at) → max(due_date) + 14d
    # Fallback se a task não tem datas: usa created_at e (created_at + 7d).
    dated = tasks.map do |t|
      start = t.started_at || t.assigned_at || t.created_at
      finish = t.due_date&.to_time || t.completed_at || (start + 7.days)
      finish = start + 1.day if finish <= start
      { task: t, start: start, finish: finish }
    end

    if dated.empty?
      @window_start, @window_end = Date.current.beginning_of_week(:monday), Date.current.end_of_week(:monday) + 14
    else
      @window_start = (dated.map { |d| d[:start] }.min.to_date - 3.days)
      @window_end   = (dated.map { |d| d[:finish] }.max.to_date + 7.days)
    end
    @window_days = (@window_end - @window_start).to_i + 1

    @rows = dated
    @today = Date.current

    # Dependências para desenhar setas — só se temos um demand específico (evita N+1 enorme no portfolio)
    @dependencies = if @demand
                      ProjectTaskDependency.includes(:predecessor, :successor)
                                           .where(predecessor_id: tasks.map(&:id))
                                           .to_a
                    else
                      []
                    end
  end
end
