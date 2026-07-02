# frozen_string_literal: true

# Bloco D — Portfólio de Evidências: documentos de projeto + evidências de dossiê, num só painel.
module Pdi
  class EvidencesController < ApplicationController
    before_action :require_gestor_or_above!

    def index
      @demands = Demand.includes(:user, documentos_attachments: :blob, defense_dossiers: :evidences)
                        .where.not(aasm_state: %w[rascunho])
                        .order(created_at: :desc)
      @demands = @demands.select { |d| d.documentos.attached? || d.defense_dossiers.any? { |dd| dd.evidences.any? } }
    end

    private

    def require_gestor_or_above!
      return if current_user&.gestor_or_above?

      redirect_to root_path, alert: "Acesso restrito ao time T&I."
    end
  end
end
