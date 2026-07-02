# frozen_string_literal: true

# Bloco D — Dossiê de defesa N3 de um projeto (Lei do Bem), com evidências anexadas.
class DemandDefenseDossiersController < ApplicationController
  before_action :set_demand
  before_action :require_gestor_or_above!
  before_action :set_dossier, only: %i[show edit update destroy]

  def index
    @dossiers = @demand.defense_dossiers.order(ano_base: :desc)
  end

  def new
    @dossier = @demand.defense_dossiers.build(ano_base: Date.current.year, status: "rascunho")
  end

  def create
    @dossier = @demand.defense_dossiers.build(dossier_params)
    @dossier.success_criteria = clean_criteria(@dossier.success_criteria)
    @dossier.created_by = current_user
    if @dossier.save
      redirect_to demand_defense_dossier_path(@demand, @dossier), notice: "Dossiê N3 criado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @evidence = DefenseEvidence.new
  end

  def edit; end

  def update
    @dossier.assign_attributes(dossier_params)
    @dossier.success_criteria = clean_criteria(@dossier.success_criteria)
    if @dossier.save
      redirect_to demand_defense_dossier_path(@demand, @dossier), notice: "Dossiê N3 atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @dossier.destroy
    redirect_to pdi_defesa_path, notice: "Dossiê removido."
  end

  def pdf
    dossier = @demand.defense_dossiers.find(params[:id])
    pdf_data = N3PdfService.new(@demand, dossier: dossier).render
    filename = "dossie_n3_#{@demand.id}_#{dossier.ano_base}.pdf"
    send_data pdf_data, filename: filename, type: "application/pdf", disposition: :attachment
  end

  private

  def clean_criteria(rows)
    Array(rows).reject { |c| c.is_a?(Hash) && c.values.all?(&:blank?) }
  end

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def set_dossier
    @dossier = @demand.defense_dossiers.find(params[:id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def dossier_params
    params.require(:defense_dossier).permit(
      :ano_base, :status, :ganhos_operacionais, :barreiras_base, :barreiras_emergentes,
      :barreiras_resolvidas, :barreiras_nao_resolvidas, :contexto_plurianual,
      :recomendacao_final, :recomendacao_notas,
      success_criteria: [ :criterio, :meta, :resultado, :status ]
    )
  end
end
