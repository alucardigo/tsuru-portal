# frozen_string_literal: true

# Bloco D — Portfólio de Elegibilidade: veredito N1 de todos os projetos, num só painel.
module Pdi
  class EligibilityController < ApplicationController
    before_action :require_gestor_or_above!

    def index
      scope = Demand.includes(:user).where.not(aasm_state: %w[rascunho])
      scope = scope.where(area_impactada: params[:area]) if params[:area].present?
      @demands = scope.order(created_at: :desc)

      @by_verdict = @demands.group_by { |d| n1_verdict(d) }
      @counts = { verde: @by_verdict["verde"]&.size || 0,
                  vermelho: @by_verdict["vermelho"]&.size || 0,
                  incompleto: @by_verdict["incompleto"]&.size || 0 }
      @filtro = params[:verdict].presence_in(%w[verde vermelho incompleto])
      @demands = @demands.select { |d| n1_verdict(d) == @filtro } if @filtro
    end

    private

    def n1_verdict(demand)
      flags = demand.n1_flags || {}
      answered = Demand::N1_FLAGS.count { |k| flags[k].in?([ true, false ]) }
      return "incompleto" if answered < Demand::N1_FLAGS.size

      flags.values.any? { |v| v == true } ? "vermelho" : "verde"
    end
    helper_method :n1_verdict

    def require_gestor_or_above!
      return if current_user&.gestor_or_above?

      redirect_to root_path, alert: "Acesso restrito ao time T&I."
    end
  end
end
