# frozen_string_literal: true

# Sprint 30 — CRUD do workflow custom (states do kanban) por demand.
class DemandTaskWorkflowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand

  DEFAULT_STATES = [
    { "key" => "backlog",      "label" => "Backlog" },
    { "key" => "a_fazer",      "label" => "A fazer" },
    { "key" => "em_andamento", "label" => "Em andamento" },
    { "key" => "em_revisao",   "label" => "Em revisão" },
    { "key" => "concluida",    "label" => "Concluída" }
  ].freeze

  def show
    @states = @demand.task_workflow_states.presence || DEFAULT_STATES
    @default = @demand.task_workflow_states.blank?
  end

  # Body: states=key1:Label1,key2:Label2,...
  def update
    raw = params[:states].to_s
    states = raw.split(",").map { |s| s.strip.split(":", 2) }.map do |k, l|
      { "key" => k.to_s.strip.parameterize.underscore, "label" => (l || k).to_s.strip }
    end.reject { |s| s["key"].blank? }
    @demand.update!(task_workflow_states: states)
    redirect_to demand_task_workflow_path(@demand), notice: "Workflow atualizado."
  end

  def destroy
    @demand.update!(task_workflow_states: [])
    redirect_to demand_task_workflow_path(@demand), notice: "Workflow resetado para o padrão."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end
end
