# frozen_string_literal: true

# Bloco G — Relatórios de IA sob demanda: resumo executivo de projeto ou insight de portfólio.
class AiReportsController < ApplicationController
  before_action :require_gestor_or_above!

  def create_for_demand
    demand = Demand.find(params[:demand_id])
    report = Ai::ReportGenerator.project_summary(demand: demand, requested_by: current_user)
    redirect_to demand_path(demand, anchor: "ia"),
                notice: (report.ok? ? "Resumo IA gerado." : "Falha ao gerar resumo: #{report.error}")
  end

  def create_portfolio
    report = Ai::ReportGenerator.portfolio_insight(requested_by: current_user)
    redirect_to dashboard_path(anchor: "ia"),
                notice: (report.ok? ? "Insight de portfólio gerado." : "Falha ao gerar insight: #{report.error}")
  end

  private

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end
end
