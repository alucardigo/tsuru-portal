# frozen_string_literal: true

# CRUD de field definitions do demand. Cada demand define seus próprios
# custom fields que aparecem no form de tarefa (inspiração ClickUp/Monday).
class DemandTaskFieldDefinitionsController < ApplicationController
  KINDS = %w[text url number select date].freeze

  before_action :authenticate_user!
  before_action :set_demand
  before_action :authorize_demand!

  def index
    @fields = @demand.task_field_definitions || []
  end

  def create
    defs = (@demand.task_field_definitions || []).dup
    kind  = params[:kind].to_s
    label = params[:label].to_s.strip
    key   = label.parameterize.underscore.presence || SecureRandom.hex(3)
    options = params[:options].to_s.split(",").map(&:strip).reject(&:blank?)
    if !KINDS.include?(kind) || label.blank?
      redirect_to demand_task_field_definitions_path(@demand), alert: "Nome e tipo obrigatórios (tipo válido: #{KINDS.join(', ')})." and return
    end
    if defs.any? { |d| d["key"] == key }
      redirect_to demand_task_field_definitions_path(@demand), alert: "Já existe um campo com essa chave." and return
    end
    defs << { "key" => key, "label" => label, "kind" => kind, "options" => options }
    @demand.update!(task_field_definitions: defs)
    redirect_to demand_task_field_definitions_path(@demand), notice: "Campo criado."
  end

  def destroy
    key = params[:id]
    defs = (@demand.task_field_definitions || []).reject { |d| d["key"] == key }
    @demand.update!(task_field_definitions: defs)
    redirect_to demand_task_field_definitions_path(@demand), notice: "Campo removido."
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def authorize_demand!
    authorize(@demand, :show?)
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão." and return
  end
end
