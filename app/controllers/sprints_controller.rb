# frozen_string_literal: true

# Sprint 20 — CRUD de Sprints dentro de um Demand + board do sprint ativo.
class SprintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand
  before_action :authorize_demand!

  def index
    @sprints = @demand.sprints.ordered
    @active_sprint = @sprints.find(&:in_progress?)
    @backlog       = @demand.tasks.where(sprint_id: nil).order(:position, :id)
  end

  def show
    @sprint = @demand.sprints.find(params[:id])
    @tasks_by_status = @sprint.project_tasks.includes(:assignee).group_by(&:kanban_status)
    @statuses = ProjectTask::KANBAN_STATUSES
  end

  def new
    @sprint = @demand.sprints.build(start_date: Date.current, end_date: Date.current + 14)
  end

  def create
    @sprint = @demand.sprints.build(sprint_params)
    if @sprint.save
      redirect_to demand_sprints_path(@demand), notice: "Sprint criada."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @sprint = @demand.sprints.find(params[:id])
    if @sprint.update(sprint_params)
      redirect_to demand_sprints_path(@demand), notice: "Sprint atualizada."
    else
      redirect_to demand_sprints_path(@demand), alert: @sprint.errors.full_messages.join(", ")
    end
  end

  def destroy
    @demand.sprints.find(params[:id]).destroy
    redirect_to demand_sprints_path(@demand), notice: "Sprint removida."
  end

  # POST /demands/:demand_id/sprints/:id/assign_task   (body: task_id)
  def assign_task
    sprint = @demand.sprints.find(params[:id])
    task = @demand.tasks.find(params[:task_id])
    task.update!(sprint_id: sprint.id)
    redirect_back fallback_location: demand_sprints_path(@demand)
  end

  # POST /demands/:demand_id/sprints/:id/unassign_task (body: task_id)
  def unassign_task
    task = @demand.tasks.find(params[:task_id])
    task.update!(sprint_id: nil)
    redirect_back fallback_location: demand_sprints_path(@demand)
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def authorize_demand!
    authorize(@demand, :show?) # reuso a DemandPolicy
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão para gerenciar sprints deste projeto." and return
  end

  def sprint_params
    params.require(:sprint).permit(:name, :goal, :start_date, :end_date, :state)
  end
end
