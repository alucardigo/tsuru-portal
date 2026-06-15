module Fi
  # Fila da consultoria FI Group: demandas aguardando parecer de elegibilidade.
  class DemandsController < BaseController
    before_action :set_demand, only: %i[show aprovar reprovar]

    def index
      scope = Demand.where(aasm_state: "em_avaliacao_fi")
                    .includes(:user, :lei_do_bem_record)
                    .order(updated_at: :desc)
      @pagy, @demands = pagy(scope)
    end

    def show
      @record = @demand.lei_do_bem_record
      @transitions = @demand.transitions.includes(:actor).order(:created_at)
      @comments = @demand.comments.includes(:user).order(created_at: :asc)
    end

    def aprovar
      parecer = params[:parecer].to_s.strip
      if parecer.length < 30
        redirect_to fi_demand_path(@demand),
                    alert: "Registre o parecer da FI (mínimo 30 caracteres)."
        return
      end

      ActiveRecord::Base.transaction do
        @demand.parecer_tecnico = "[Parecer FI Group] #{parecer}"
        @demand.fi_aprovar
        @demand.save!
        @demand.comments.create!(user: current_user, body: "[FI Group — ELEGÍVEL] #{parecer}")
      end
      redirect_to fi_demands_path, notice: "Parecer FI registrado: ELEGÍVEL Lei do Bem."
    rescue StandardError => e
      redirect_to fi_demand_path(@demand), alert: "Não foi possível registrar o parecer: #{e.message}"
    end

    def reprovar
      parecer = params[:parecer].to_s.strip
      if parecer.length < 30
        redirect_to fi_demand_path(@demand),
                    alert: "Registre a justificativa de não elegibilidade (mínimo 30 caracteres)."
        return
      end

      ActiveRecord::Base.transaction do
        @demand.parecer_tecnico = "[Parecer FI Group] #{parecer}"
        @demand.fi_reprovar
        @demand.save!
        @demand.comments.create!(user: current_user, body: "[FI Group — NÃO ELEGÍVEL] #{parecer}")
      end
      redirect_to fi_demands_path, notice: "Parecer FI registrado: NÃO elegível."
    rescue StandardError => e
      redirect_to fi_demand_path(@demand), alert: "Não foi possível registrar o parecer: #{e.message}"
    end

    private

    def set_demand
      @demand = Demand.find(params[:id])
    end
  end
end
