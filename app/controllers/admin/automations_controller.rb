# frozen_string_literal: true

module Admin
  class AutomationsController < BaseController
    def index
      @automations = TaskAutomation.order(created_at: :desc)
      @automation  = TaskAutomation.new
      @llm_ready   = LlmProvider.enabled.exists?
    end

    def create
      automation = TaskAutomation.new(
        name:          params.require(:name),
        trigger_event: params.require(:trigger_event),
        demand_id:     params[:demand_id].presence,
        action:        { "kind" => params.require(:action_kind) },
        enabled:       true
      )
      if automation.save
        redirect_to admin_automations_path, notice: "Automação \"#{automation.name}\" criada."
      else
        redirect_to admin_automations_path, alert: automation.errors.full_messages.join(", ")
      end
    end

    def update
      automation = TaskAutomation.find(params[:id])
      automation.update(enabled: params[:enabled] == "true")
      redirect_to admin_automations_path
    end

    def destroy
      TaskAutomation.find(params[:id]).destroy
      redirect_to admin_automations_path, notice: "Automação removida."
    end
  end
end
