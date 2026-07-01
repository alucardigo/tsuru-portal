# frozen_string_literal: true

class ProjectTaskTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand

  def index
    @templates = @demand.templates.order(:name)
    @template  = ProjectTaskTemplate.new
  end

  def create
    checklist = params[:checklist].to_s.split("\n").map(&:strip).reject(&:blank?)
    tpl = @demand.templates.build(
      name: params.require(:name),
      payload: {
        title: params[:title],
        description: params[:description],
        priority: params[:priority].presence || "media",
        estimated_hours: params[:estimated_hours].presence&.to_f,
        checklist: checklist
      }
    )
    if tpl.save
      redirect_to demand_task_templates_path(@demand), notice: "Template criado."
    else
      redirect_to demand_task_templates_path(@demand), alert: tpl.errors.full_messages.join(", ")
    end
  end

  # POST /demands/:demand_id/task_templates/:id/apply → cria task e vai pro kanban
  def apply
    tpl = @demand.templates.find(params[:id])
    task = tpl.apply_to(demand: @demand, creator: current_user)
    if task.persisted?
      redirect_to kanban_demand_tasks_path(@demand), notice: "Tarefa criada de \"#{tpl.name}\"."
    else
      redirect_to demand_task_templates_path(@demand), alert: task.errors.full_messages.join(", ")
    end
  end

  def destroy
    @demand.templates.find(params[:id]).destroy
    redirect_to demand_task_templates_path(@demand), notice: "Template removido."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end
end
