class DashboardController < ApplicationController
  def show
    @stats = build_stats
    @recent_demands = scoped_demands.order(updated_at: :desc).limit(10)
    @pending_triagem = Demand.where(aasm_state: "submetida").order(created_at: :asc).limit(10) if current_user.gestor_or_above?
    @pending_n2 = Demand.where(aasm_state: "n1_aprovada").order(created_at: :asc).limit(10) if current_user.analista_pdi? || current_user.admin?
  end

  private

  def scoped_demands
    if current_user.colaborador?
      current_user.demands
    else
      Demand.all
    end
  end

  def build_stats
    base = scoped_demands
    {
      total: base.count,
      rascunho: base.where(aasm_state: "rascunho").count,
      submetidas: base.where(aasm_state: "submetida").count,
      em_triagem: base.where(aasm_state: "em_triagem").count,
      aprovadas: base.where(aasm_state: "n1_aprovada").count,
      elegiveis: base.where(aasm_state: "elegivel").count
    }
  end
end
