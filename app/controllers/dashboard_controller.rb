class DashboardController < ApplicationController
  def show
    @stats = build_stats
    @recent_demands = scoped_demands.order(updated_at: :desc).limit(10)

    # Filas por papel (fluxo INOVA BEL de 6 etapas)
    if current_user.gestor? || current_user.admin?
      @pending_supervisor = Demand.where(aasm_state: "submetida").order(created_at: :asc).limit(10)
    end
    if current_user.analista_pdi? || current_user.admin?
      @pending_triagem = Demand.where(aasm_state: "aprovada_supervisor").order(created_at: :asc).limit(10)
      @pending_n2 = Demand.where(aasm_state: "n1_aprovada").order(created_at: :asc).limit(10)
    end
    if current_user.fi? || current_user.admin?
      @pending_fi = Demand.where(aasm_state: "em_avaliacao_fi").order(created_at: :asc).limit(10)
    end
  end

  private

  def scoped_demands
    if current_user.colaborador?
      current_user.demands
    elsif current_user.fi?
      Demand.where(aasm_state: %w[em_avaliacao_fi elegivel nao_elegivel projeto])
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
      em_triagem: base.where(aasm_state: %w[aprovada_supervisor em_triagem]).count,
      aprovadas: base.where(aasm_state: %w[n1_aprovada n2_em_andamento n2_completa]).count,
      em_fi: base.where(aasm_state: "em_avaliacao_fi").count,
      elegiveis: base.where(aasm_state: "elegivel").count,
      projetos: base.where(aasm_state: %w[projeto in_execution concluida]).count
    }
  end
end
