# frozen_string_literal: true

# Bloco D — Portfólio de Composição de Defesa: projetos elegíveis a virar dossiê N3.
module Pdi
  class DefensesController < ApplicationController
    before_action :require_gestor_or_above!

    ELEGIVEIS_STATES = %w[elegivel projeto in_execution concluida].freeze

    def index
      @demands = Demand.includes(:user, :defense_dossiers)
                        .where(aasm_state: ELEGIVEIS_STATES)
                        .order(created_at: :desc)
    end

    private

    def require_gestor_or_above!
      return if current_user&.gestor_or_above?

      redirect_to root_path, alert: "Acesso restrito ao time T&I."
    end
  end
end
