# frozen_string_literal: true

# Toggle "Seguir tarefa" — inspirado em Jira/ClickUp/Wrike.
class ProjectTaskWatchersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_and_task
  before_action :authorize_task!

  def create
    @task.task_watchers.find_or_create_by(user_id: current_user.id)
    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Você está seguindo esta tarefa."
  end

  def destroy
    @task.task_watchers.where(user_id: current_user.id).destroy_all
    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Deixou de seguir."
  end

  private

  def set_demand_and_task
    @demand = Demand.find(params[:demand_id])
    @task = @demand.tasks.find(params[:task_id])
  end

  def authorize_task!
    authorize(@task, :show?, policy_class: ProjectTaskPolicy)
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão." and return
  end
end
