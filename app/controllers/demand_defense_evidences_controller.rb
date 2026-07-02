# frozen_string_literal: true

# Bloco D — Evidências (Bloco 7 do dossiê N3) anexadas a um dossiê de defesa.
class DemandDefenseEvidencesController < ApplicationController
  before_action :set_dossier
  before_action :require_gestor_or_above!

  def create
    evidence = @dossier.evidences.build(evidence_params)
    evidence.arquivo.attach(params[:defense_evidence][:arquivo]) if params.dig(:defense_evidence, :arquivo).present?

    if evidence.save
      redirect_to demand_defense_dossier_path(@demand, @dossier), notice: "Evidência adicionada."
    else
      redirect_to demand_defense_dossier_path(@demand, @dossier), alert: evidence.errors.full_messages.join(", ")
    end
  end

  def destroy
    @dossier.evidences.find(params[:id]).destroy
    redirect_to demand_defense_dossier_path(@demand, @dossier), notice: "Evidência removida."
  end

  private

  def set_dossier
    @demand = Demand.find(params[:demand_id])
    @dossier = @demand.defense_dossiers.find(params[:defense_dossier_id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def evidence_params
    params.require(:defense_evidence).permit(:tipo, :descricao)
  end
end
