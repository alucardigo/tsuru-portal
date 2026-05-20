class PipelineController < ApplicationController
  before_action :require_gestor_or_above!

  COLUMNS = [
    { key: "triagem",    label: "Triagem N1",     states: %w[submetida em_triagem] },
    { key: "n2",         label: "Avaliação N2",   states: %w[n1_aprovada n2_em_andamento n2_completa awaiting_requester] },
    { key: "decisao",    label: "Decisão",        states: %w[board_review] },
    { key: "execucao",   label: "PD&I executando", states: %w[elegivel in_execution] },
    { key: "concluido",  label: "Concluído",      states: %w[concluida arquivada] },
    { key: "rejeitado",  label: "Não elegíveis",  states: %w[n1_reprovada nao_elegivel cancelada] }
  ].freeze

  def show
    @columns = COLUMNS.map do |col|
      demands = Demand.where(aasm_state: col[:states])
                      .includes(:user)
                      .order(updated_at: :desc)
                      .limit(15)
      col.merge(demands: demands, total: Demand.where(aasm_state: col[:states]).count)
    end
  end

  private

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end
end
