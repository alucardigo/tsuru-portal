# frozen_string_literal: true

class ProjectTaskAttachmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand_and_task
  before_action :authorize_task!

  def destroy
    blob = @task.attachments.find_by(id: params[:id])
    blob&.purge
    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Anexo removido."
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
