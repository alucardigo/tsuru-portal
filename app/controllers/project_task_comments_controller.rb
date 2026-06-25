# frozen_string_literal: true

class ProjectTaskCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_and_task
  before_action :authorize_task!

  def create
    @comment = @task.comments.create!(user: current_user, body: params.require(:project_task_comment).require(:body))
    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Comentário adicionado."
  end

  def destroy
    @comment = @task.comments.find(params[:id])
    if @comment.user_id == current_user.id || current_user.admin?
      @comment.destroy!
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Comentário removido."
    else
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), alert: "Sem permissão."
    end
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
