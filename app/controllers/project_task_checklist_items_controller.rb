# frozen_string_literal: true

class ProjectTaskChecklistItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_and_task
  before_action :authorize_task!

  def create
    @task.checklist_items.create!(title: params.require(:title), position: (@task.checklist_items.maximum(:position) || -1) + 1)
    redirect_back fallback_location: edit_demand_task_path(@demand, @task)
  end

  def toggle
    item = @task.checklist_items.find(params[:id])
    item.update!(done: !item.done)
    redirect_back fallback_location: edit_demand_task_path(@demand, @task)
  end

  def destroy
    @task.checklist_items.find(params[:id]).destroy!
    redirect_back fallback_location: edit_demand_task_path(@demand, @task)
  end

  private

  def set_demand_and_task
    @demand = Demand.find(params[:demand_id])
    @task = @demand.tasks.find(params[:task_id])
  end

  def authorize_task!
    authorize(@task, :update?, policy_class: ProjectTaskPolicy)
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão para esta tarefa." and return
  end
end
