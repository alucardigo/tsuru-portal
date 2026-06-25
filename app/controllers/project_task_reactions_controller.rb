# frozen_string_literal: true

# Toggle emoji reaction num comentário de tarefa. Estilo Linear/Slack.
class ProjectTaskReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_task_comment
  before_action :authorize_task!

  def toggle
    emoji = params.require(:emoji)
    existing = @comment.reactions.where(user_id: current_user.id, emoji: emoji).first
    if existing
      existing.destroy
    else
      @comment.reactions.create!(user_id: current_user.id, emoji: emoji)
    end
    redirect_back fallback_location: edit_demand_task_path(@demand, @task)
  end

  private

  def set_demand_task_comment
    @demand = Demand.find(params[:demand_id])
    @task = @demand.tasks.find(params[:task_id])
    @comment = @task.comments.find(params[:comment_id])
  end

  def authorize_task!
    authorize(@task, :show?, policy_class: ProjectTaskPolicy)
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão." and return
  end
end
