module Board
  class DemandsController < BaseController
    before_action :set_demand, only: %i[show approve reject defer encaminhar_fi]

    def index
      scope = Demand.where(aasm_state: "board_review").includes(:user, :lei_do_bem_record).order(updated_at: :desc)
      @pagy, @demands = pagy(scope)
    end

    def show
      @record = @demand.lei_do_bem_record
      @benefit = if @record
                   res = Calculators::LeiDoBemBenefit.call(record: @record)
                   res.success? ? res.payload : nil
                 end
      @transitions = @demand.transitions.includes(:actor).order(:created_at)
    end

    def approve
      apply_decision!(outcome: "approved", event: :marcar_elegivel)
    end

    def reject
      apply_decision!(outcome: "rejected", event: :marcar_nao_elegivel)
    end

    def defer
      apply_decision!(outcome: "deferred", event: nil)
    end

    # Etapa 4 -> 5: diretoria aprova e encaminha à FI Group
    def encaminhar_fi
      apply_decision!(outcome: "approved", event: :aprovar_diretoria,
                      notice_ok: "Aprovado pela diretoria e encaminhado à FI Group.")
    end

    private

    def set_demand
      @demand = Demand.find(params[:id])
    end

    def apply_decision!(outcome:, event:, notice_ok: nil)
      justification = params[:justification].to_s

      decision = @demand.board_decisions.build(
        decider: current_user,
        outcome: outcome,
        justification: justification,
        estimated_benefit: estimated_benefit_for(@demand)
      )

      if decision.invalid?
        redirect_to board_demand_path(@demand),
                    alert: "Justificativa precisa ter no mínimo 100 caracteres. (#{justification.length} agora)"
        return
      end

      ActiveRecord::Base.transaction do
        decision.save!
        if event
          @demand.public_send(event)
          @demand.save!
        end
      end

      redirect_to board_demands_path,
                  notice: notice_ok ||
                          (outcome == "approved" ? "Projeto aprovado pela diretoria." :
                           outcome == "rejected" ? "Projeto rejeitado." :
                           "Decisão adiada — registrada no histórico.")
    end

    def estimated_benefit_for(demand)
      record = demand.lei_do_bem_record
      return nil unless record

      res = Calculators::LeiDoBemBenefit.call(record: record)
      res.success? ? res.payload[:economia_tributaria] : nil
    end
  end
end
