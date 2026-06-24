# frozen_string_literal: true

class ProjectTaskDependenciesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_and_task

  def create
    predecessor = @demand.tasks.find_by(id: params[:predecessor_id])
    if predecessor.nil?
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), alert: "Tarefa predecessora inválida." and return
    end
    dep = ProjectTaskDependency.new(predecessor: predecessor, successor: @task)
    if dep.save
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Dependência criada."
    else
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), alert: dep.errors.full_messages.join(", ")
    end
  end

  def destroy
    dep = ProjectTaskDependency.find_by(id: params[:id])
    dep&.destroy
    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Dependência removida."
  end

  private

  def set_demand_and_task
    @demand = Demand.find(params[:demand_id])
    @task = @demand.tasks.find(params[:task_id])
  end
end
