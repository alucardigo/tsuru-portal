# frozen_string_literal: true

# POST /demands/:demand_id/tasks/bulk — aplica op em lote
#   Body: task_ids[]=..., op=... , value=...
#   ops: status, priority, assignee, archive, delete
class ProjectTaskBulksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand

  def create
    ids = Array(params[:task_ids]).map(&:to_i).reject(&:zero?)
    op = params[:op]
    value = params[:value]
    scope = @demand.tasks.where(id: ids)
    count = scope.count
    redirect_back fallback_location: kanban_demand_tasks_path(@demand), alert: "Nenhuma tarefa selecionada." and return if count.zero?

    case op
    when "status"
      scope.update_all(kanban_status: value) if ProjectTask::KANBAN_STATUSES.include?(value)
    when "priority"
      scope.update_all(priority: value) if ProjectTask::PRIORITIES.include?(value)
    when "assignee"
      new_id = value.presence&.to_i
      scope.find_each { |t| t.update!(assignee_id: new_id) }
    when "archive"
      scope.update_all(kanban_status: "concluida")  # arquivar simples: move para concluída
    when "delete"
      scope.destroy_all
    else
      redirect_back fallback_location: kanban_demand_tasks_path(@demand), alert: "Operação inválida." and return
    end

    redirect_back fallback_location: kanban_demand_tasks_path(@demand), notice: "#{count} tarefa(s) atualizada(s) (#{op})."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end
end
