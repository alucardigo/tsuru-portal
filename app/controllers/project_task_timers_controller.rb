# frozen_string_literal: true

# Inicia/para o cronômetro de uma tarefa para o usuário atual.
class ProjectTaskTimersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand
  before_action :set_task

  # POST /demands/:demand_id/tasks/:task_id/timer/start
  def start
    @task.time_entries.create!(user: current_user, started_at: Time.current)

    # Move ao iniciar: backlog/a_fazer/em_revisao → em_andamento. Salva estado anterior.
    if @task.kanban_status != "em_andamento" && @task.kanban_status != "concluida"
      @task.update!(prev_kanban_status: @task.kanban_status, kanban_status: "em_andamento")
    end

    redirect_back fallback_location: kanban_demand_tasks_path(@demand), notice: "Cronômetro iniciado."
  end

  # POST /demands/:demand_id/tasks/:task_id/timer/stop
  def stop
    entry = @task.time_entries.running.where(user_id: current_user.id).order(started_at: :desc).first
    if entry
      now      = Time.current
      duration = [ (now - entry.started_at).to_i, 0 ].max
      entry.update!(ended_at: now, duration_seconds: duration)
      @task.update!(spent_hours: (@task.spent_hours.to_f + duration / 3600.0).round(2))
    end

    # Restaura status anterior se ainda estava em "em_andamento" por causa do timer
    if @task.kanban_status == "em_andamento" && @task.prev_kanban_status.present?
      @task.update!(kanban_status: @task.prev_kanban_status, prev_kanban_status: nil)
    end

    redirect_back fallback_location: kanban_demand_tasks_path(@demand), notice: "Cronômetro pausado."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def set_task
    @task = @demand.tasks.find(params[:id])
  end
end
