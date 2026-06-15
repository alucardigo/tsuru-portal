module Admin
  # Auditoria do Sistema — feed central de transições de estado (DemandTransition)
  # e alterações de registros (PaperTrail versions). Admin-only.
  class AuditsController < BaseController
    def index
      transitions = DemandTransition.includes(:actor, :demand).order(created_at: :desc)
      transitions = transitions.where(event: params[:event]) if params[:event].present?
      if params[:actor_id].present?
        transitions = transitions.where(actor_id: params[:actor_id])
      end
      if params[:demand_id].present?
        transitions = transitions.where(demand_id: params[:demand_id])
      end
      if params[:data_ini].present?
        transitions = transitions.where("created_at >= ?", params[:data_ini].to_date.beginning_of_day)
      end
      if params[:data_fim].present?
        transitions = transitions.where("created_at <= ?", params[:data_fim].to_date.end_of_day)
      end

      @pagy, @transitions = pagy(transitions, limit: 40)

      # Alterações de registros (criação/edição) — últimas 30
      @versions = PaperTrail::Version.order(created_at: :desc).limit(30)

      # Filtros disponíveis
      @eventos   = DemandTransition.distinct.pluck(:event).compact.sort
      @atores    = User.where(id: DemandTransition.distinct.pluck(:actor_id).compact).order(:name)
      @total     = DemandTransition.count
    end
  end
end
